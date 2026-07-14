# OrangePi Zero 3 - Tailscale Exit Node e Subnet Router

Este guia configura uma **OrangePi Zero 3** para utilizar o **Tailscale** como:

- **Exit Node**, permitindo que outros dispositivos utilizem a conexão de Internet da OrangePi.
- **Subnet Router**, anunciando automaticamente a rede local (LAN) para toda a Tailnet.
- Servidor preparado para manter todas essas configurações de forma persistente após reinicializações.

Ao final deste guia, a OrangePi estará pronta para oferecer acesso remoto seguro à rede local através do Tailscale, permitindo tanto o roteamento completo do tráfego (Exit Node) quanto o acesso transparente aos dispositivos da LAN (Subnet Router).

---

# 1. Instalar o Tailscale

Instale o Tailscale utilizando o instalador oficial.

```bash
curl -fsSL https://tailscale.com/install.sh | sh

# Autenticar o dispositivo
tailscale up
```

Após executar `tailscale up`, siga o link exibido no terminal para autenticar a OrangePi na sua conta do Tailscale.

---

# 2. Habilitar o encaminhamento de pacotes (IP Forwarding)

Para que a OrangePi possa atuar como **Exit Node** e **Subnet Router**, é necessário habilitar o encaminhamento de pacotes IPv4 e IPv6.

Criar o arquivo:

```bash
nano /etc/sysctl.d/99-tailscale.conf
```

Conteúdo:

```conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

Aplicar as configurações:

```bash
sysctl -p /etc/sysctl.d/99-tailscale.conf

cat /etc/sysctl.d/99-tailscale.conf
```

---

# 3. Configurar o anúncio automático da Subnet

Para evitar alterações manuais sempre que a rede local mudar, utilizaremos o **networkd-dispatcher** para detectar automaticamente a subnet configurada na interface Ethernet (`end0`) e atualizá-la no Tailscale.

Instalar as dependências:

```bash
apt install -y networkd-dispatcher jq

nano /etc/networkd-dispatcher/routable.d/50-tailscale-route
```

Conteúdo:

```bash
#!/bin/bash
set -euo pipefail

LOGGER_TAG="tailscale-subnet-router"

# Executa apenas para a interface Ethernet principal
[ "$IFACE" != "end0" ] && exit 0

# Aguarda o tailscaled ficar ativo (máximo 30 segundos)
for i in {1..30}; do
    systemctl is-active --quiet tailscaled && break
    sleep 1
done

systemctl is-active --quiet tailscaled || exit 0

# Descobre automaticamente a subnet IPv4 da interface
ROUTE=$(ip -4 route show dev "$IFACE" proto kernel | awk '{print $1}')

[ -z "$ROUTE" ] && exit 0

logger -t "$LOGGER_TAG" "Subnet detectada: $ROUTE"

# Rotas atualmente anunciadas pelo Tailscale
CURRENT=$(tailscale debug prefs | jq -r '.AdvertiseRoutes // [] | .[]' 2>/dev/null)

# Se a subnet já estiver anunciada, não altera a configuração
if printf '%s\n' "$CURRENT" | grep -qxF "$ROUTE"; then
    logger -t "$LOGGER_TAG" "Rota $ROUTE já anunciada."
    exit 0
fi

logger -t "$LOGGER_TAG" "Atualizando rota anunciada para $ROUTE"

tailscale set \
    --advertise-routes="$ROUTE" \
    --advertise-exit-node \
    --accept-routes
```

Dar permissão de execução e reiniciar o serviço:

```bash
chmod +x /etc/networkd-dispatcher/routable.d/50-tailscale-route

cat /etc/networkd-dispatcher/routable.d/50-tailscale-route

systemctl restart networkd-dispatcher
```

> **Importante:** este script identifica automaticamente a rede IPv4 configurada na interface `end0` e a anuncia no Tailscale. Caso a subnet da LAN seja alterada futuramente, o anúncio será atualizado automaticamente, sem necessidade de editar o script.

---

# 4. Habilitar UDP GRO Forwarding

O Tailscale recomenda habilitar o recurso **UDP GRO Forwarding** para melhorar o desempenho quando o dispositivo atua como **Exit Node**, reduzindo o processamento de pacotes e aumentando a eficiência da interface de rede.

Aplicar imediatamente:

```bash
networkctl reconfigure end0

tailscale debug prefs | grep -A5 AdvertiseRoutes

ethtool -K end0 rx-udp-gro-forwarding on

ethtool -k end0 | grep udp

nano /etc/systemd/system/ethtool-end0.service
```

Conteúdo:

```ini
[Unit]
Description=Enable UDP GRO forwarding on end0
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -K end0 rx-udp-gro-forwarding on
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Validar e habilitar:

```bash
cat /etc/systemd/system/ethtool-end0.service

systemctl daemon-reload

systemctl enable ethtool-end0.service

systemctl start ethtool-end0.service
```

Essa configuração garante que o recurso seja habilitado automaticamente a cada inicialização do sistema.

---

# 5. Verificações locais

Antes de utilizar a OrangePi como Exit Node e Subnet Router, confirme que todos os serviços necessários estão habilitados e que o recurso UDP GRO está ativo.

```bash
ethtool -k end0 | grep udp

systemctl is-enabled tailscaled

systemctl is-enabled networkd-dispatcher

systemctl is-enabled ethtool-end0.service
```

Resultado esperado:

- `tailscaled` → **enabled**
- `networkd-dispatcher` → **enabled**
- `ethtool-end0.service` → **enabled**
- `rx-udp-gro-forwarding` → **on**

---

# 6. Aprovar no Admin Console e validar

Acesse o **Admin Console** do Tailscale e aprove:

- **Exit Node**
- **Subnet Route**

Após a aprovação, execute:

```bash
tailscale status

tailscale debug prefs | grep -A5 AdvertiseRoutes

tailscale netcheck
```

Esses comandos confirmam que:

- o dispositivo está conectado à Tailnet;
- a subnet está sendo anunciada corretamente;
- o Exit Node está disponível para os demais dispositivos;
- a conectividade da rede Tailscale está funcionando normalmente.

---
