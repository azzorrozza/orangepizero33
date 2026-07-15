# OrangePi Zero 3 - Unbound Recursive DNS + DNSSEC

Este guia configura a OrangePi Zero 3 para utilizar o **Unbound** como servidor DNS recursivo local, com **cache**, **DNSSEC** e integração correta com o **systemd-resolved**.

O objetivo desta configuração é servir como base para a instalação posterior do **Pi-hole em Docker**.

Nesta arquitetura:

```
Clientes
     │
     ▼
Pi-hole (Docker :53)
     │
     ▼
Unbound (Host :5335)
     │
     ▼
Root DNS Servers
```

O Unbound permanece instalado diretamente no sistema operacional, enquanto o Pi-hole será executado em um contêiner Docker utilizando a porta 53.

---

# 1. Instalar o Unbound

> **Importante (Debian 13 / Armbian Trixie):**
>
> Além do Unbound, instale também o pacote **dns-root-data**. Ele fornece o arquivo `/usr/share/dns/root.key`, utilizado pelo helper do Debian para atualizar automaticamente a Trust Anchor durante o boot.
>
> Sem esse pacote o serviço funciona normalmente, porém o `ExecStartPre=root_trust_anchor_update` termina com `status=1/FAILURE`.

Instalação:

```bash
apt update
apt install -y unbound unbound-anchor dns-root-data dnsutils libnss-resolve
```

Habilitar o serviço:

```bash
systemctl enable unbound
```

---

# 2. Configurar o systemd-resolved

O **systemd-resolved** continuará sendo utilizado apenas para gerenciamento da resolução do sistema.

Como o Pi-hole utilizará posteriormente a porta **53**, o DNS Stub Listener deve ser desabilitado.

Editar:

```bash
nano /etc/systemd/resolved.conf
```

Conteúdo:

```ini
[Resolve]
DNS=1.1.1.1 9.9.9.9
DNSStubListener=no
```

Reiniciar:

```bash
systemctl restart systemd-resolved
```

Verificar:

```bash
resolvectl status
```

Deverá aparecer algo semelhante a:

```
DNS Servers: 1.1.1.1 9.9.9.9
```

> **Por que utilizar Cloudflare e Quad9?**
>
> Durante a instalação do Docker e dos containers, o host precisa resolver nomes como `registry-1.docker.io`.
>
> Se o sistema apontar para si mesmo (127.0.0.1) antes do Pi-hole existir, o Docker poderá ficar sem resolução de nomes e não conseguirá baixar imagens.

---

# 3. Configurar o Unbound

Editar:

```bash
nano /etc/unbound/unbound.conf.d/recursive.conf
```

Conteúdo:

```conf
server:
    module-config: "validator iterator"

    interface: 127.0.0.1
    interface: ::1

    port: 5335

    do-ip4: yes
    do-ip6: yes

    do-udp: yes
    do-tcp: yes

    prefer-ip6: no

    hide-identity: yes
    hide-version: yes

    harden-glue: yes
    harden-dnssec-stripped: yes

    qname-minimisation: yes

    prefetch: yes
    prefetch-key: yes

    rrset-roundrobin: yes

    cache-min-ttl: 300
    cache-max-ttl: 86400

    msg-cache-size: 32m
    rrset-cache-size: 64m

    outgoing-range: 128
    num-threads: 1

    so-rcvbuf: 4m
    so-sndbuf: 4m

    unwanted-reply-threshold: 10000

    minimal-responses: yes

    use-caps-for-id: no

    edns-buffer-size: 1232

    access-control: 127.0.0.0/8 allow
    access-control: ::1 allow

    verbosity: 1
```

> O Unbound ficará acessível apenas localmente (`127.0.0.1:5335`).
>
> Posteriormente o Pi-hole será o único cliente do Unbound.

---

# 4. Inicializar a Trust Anchor (DNSSEC)

Criar diretório:

```bash
mkdir -p /var/lib/unbound
```

Gerar a Trust Anchor:

```bash
unbound-anchor -a /var/lib/unbound/root.key
```

Permissões:

```bash
chown unbound:unbound /var/lib/unbound/root.key
chmod 644 /var/lib/unbound/root.key
```

Verificar:

```bash
ls -l /var/lib/unbound/root.key
```

Resultado esperado:

```text
-rw-r--r-- 1 unbound unbound ...
```

---

# 5. Validar a configuração

```bash
unbound-checkconf
```

Verificar também:

```bash
unbound-checkconf -o interface
unbound-checkconf -o port
```

Resultado esperado:

```
127.0.0.1
::1
5335
```

---

# 6. Iniciar o serviço

```bash
systemctl restart unbound
```

Verificar:

```bash
systemctl status unbound --no-pager
```

Resultado esperado:

```
Active: active (running)
```

---

# 7. Verificar o helper da Trust Anchor

Executar:

```bash
/usr/libexec/unbound-helper root_trust_anchor_update
echo $?
```

Resultado esperado:

```
0
```

Caso retorne `1`, confirme:

```bash
dpkg -l dns-root-data
```

e

```bash
ls -l /usr/share/dns/root.key
```

Se necessário:

```bash
apt install dns-root-data
```

---

# 8. Verificar o resolv.conf

O `/etc/resolv.conf` deve continuar sendo administrado pelo **systemd-resolved**.

Verifique:

```bash
ls -l /etc/resolv.conf
```

Ele deverá apontar para:

```
/run/systemd/resolve/resolv.conf
```

ou

```
/run/systemd/resolve/stub-resolv.conf
```

Não substitua esse arquivo manualmente.

---

# 9. Impedir que o DHCP sobrescreva o DNS

Desabilite o recebimento automático de DNS via DHCP.

```bash
systemctl mask unbound-resolvconf.service
systemctl reset-failed
```

Editar:

```bash
nano /etc/netplan/*.yaml
```

Adicionar:

```yaml
dhcp4-overrides:
  use-dns: false

dhcp6-overrides:
  use-dns: false
```

Aplicar:

```bash
netplan generate
netplan apply
```

---

# Testes

## Testar o Unbound

```bash
dig @127.0.0.1 -p 5335 openai.com
```

---

## Testar DNSSEC

```bash
dig @127.0.0.1 -p 5335 dnssec-failed.org
```

Resultado esperado:

```
status: SERVFAIL
```

---

## Verificar a porta

```bash
ss -lnptu | grep 5335
```

Resultado esperado:

```
udp ... 127.0.0.1:5335
tcp ... 127.0.0.1:5335
```

Todos pertencentes ao processo **unbound**.

---

## Verificar estatísticas

```bash
unbound-control stats_noreset
```

Os contadores de cache deverão aumentar conforme o servidor for utilizado.

---

# Próximo passo

O próximo guia instalará o **Pi-hole em Docker**.

Ele ficará responsável por:

- publicar a porta **53** para a rede;
- encaminhar todas as consultas para `127.0.0.1#5335`;
- fornecer bloqueio de anúncios;
- disponibilizar a interface web de administração.

Como o host continuará utilizando DNS públicos (Cloudflare/Quad9) através do `systemd-resolved`, o Docker sempre conseguirá resolver nomes e baixar imagens, evitando o problema de dependência circular encontrado durante a instalação.
