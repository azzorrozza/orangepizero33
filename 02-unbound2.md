# OrangePi Zero 3 - Unbound Recursive DNS + DNSSEC

Este guia configura a OrangePi Zero 3 para utilizar o **Unbound** como servidor DNS recursivo local, com **cache**, **DNSSEC** e integração correta com o **systemd-resolved**.

Diferentemente da configuração tradicional, o Unbound será executado na **porta 5335**, deixando a **porta 53 livre** para a futura instalação do **Pi-hole**.

Ao final deste guia:

- O sistema operacional utilizará o Unbound através do `systemd-resolved`;
- O Unbound fará resolução recursiva diretamente na Internet;
- A validação **DNSSEC** estará habilitada;
- A porta **53 permanecerá livre** para o Pi-hole.

---

# Arquitetura

```
                 Clientes LAN (futuro)
                         │
                         ▼
                  Pi-hole (53)
                         │
                127.0.0.1#5335
                         │
                         ▼
               Unbound Recursivo (5335)
                         │
                         ▼
                 Root DNS Servers


Sistema Operacional
        │
        ▼
systemd-resolved
        │
DNS=127.0.0.1:5335
        │
        ▼
 Unbound (5335)
```

---

# 1. Instalar o Unbound

> **Importante (Debian 13 / Armbian Trixie):**
>
> Além do Unbound, instale também o pacote **dns-root-data**. Ele fornece o arquivo `/usr/share/dns/root.key`, utilizado pelo helper do Debian para atualizar automaticamente a Trust Anchor durante o boot.

Instalação:

```bash
apt update

apt install -y \
    unbound \
    unbound-anchor \
    dns-root-data \
    dnsutils \
    libnss-resolve
```

Habilitar o serviço:

```bash
systemctl enable unbound
```

---

# 2. Configurar o systemd-resolved

Desabilite apenas o **DNS Stub Listener**, mantendo o serviço ativo.

Editar:

```bash
nano /etc/systemd/resolved.conf
```

Adicionar ou alterar:

```ini
[Resolve]
DNS=127.0.0.1:5335
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

O servidor DNS deverá aparecer como:

```
127.0.0.1:5335
```

---

# 3. Configurar o Unbound

Criar o arquivo:

```bash
nano /etc/unbound/unbound.conf.d/recursive.conf
```

Conteúdo:

```conf
server:
    module-config: "validator iterator"

    interface: 0.0.0.0
    interface: ::0

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
    access-control: 192.168.1.0/24 allow
    access-control: 100.64.0.0/10 allow

    verbosity: 1
```

> **Altere a rede `192.168.1.0/24` para a subnet da sua LAN.**

---

# 4. Inicializar a Trust Anchor (DNSSEC)

Criar o diretório:

```bash
mkdir -p /var/lib/unbound
```

Gerar a Trust Anchor:

```bash
unbound-anchor -a /var/lib/unbound/root.key
```

Corrigir permissões:

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
-rw-r--r-- 1 unbound unbound ... /var/lib/unbound/root.key
```

---

# 5. Validar a configuração

```bash
unbound-checkconf
```

Verificar a interface:

```bash
unbound-checkconf -o interface
```

Verificar a porta:

```bash
unbound-checkconf -o port
```

Resultado esperado:

```text
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

```text
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

```text
0
```

Caso retorne:

```text
1
```

Verifique:

```bash
dpkg -l dns-root-data

ls -l /usr/share/dns/root.key
```

Caso necessário:

```bash
apt install dns-root-data
```

---

# 8. Verificar o resolv.conf

O arquivo deve continuar sendo gerenciado pelo `systemd-resolved`.

Verificar:

```bash
ls -l /etc/resolv.conf
```

Resultado esperado:

```
/run/systemd/resolve/stub-resolv.conf
```

ou

```
/run/systemd/resolve/resolv.conf
```

Não substitua esse link simbólico.

---

# Testes

## Testar o próprio Unbound

```bash
dig @127.0.0.1 -p 5335 openai.com
```

---

## Testar pela interface da LAN

```bash
dig @192.168.1.20 -p 5335 openai.com
```

(Substitua pelo IP da OrangePi.)

A primeira consulta será mais lenta.

As seguintes deverão utilizar o cache.

---

## Testar DNSSEC

```bash
dig @127.0.0.1 -p 5335 dnssec-failed.org
```

Resultado esperado:

```text
status: SERVFAIL
```

---

## Verificar a porta utilizada

```bash
ss -lnptu | grep 5335
```

Resultado esperado:

```text
udp   ... 0.0.0.0:5335
udp   ... [::]:5335
tcp   ... 0.0.0.0:5335
tcp   ... [::]:5335
```

Todos pertencentes ao processo **unbound**.

---

## Verificar estatísticas

```bash
unbound-control stats_noreset
```

Os contadores como:

- cachehits
- cachemiss
- recursivereplies

deverão aumentar conforme o servidor for utilizado.

---

# Preparação para o Pi-hole

Nenhuma alteração adicional será necessária no Unbound quando o Pi-hole for instalado.

Bastará configurar o Pi-hole para utilizar como servidor upstream:

```
127.0.0.1#5335
```

Dessa forma:

- o Pi-hole atenderá as consultas DNS na **porta 53**;
- o Unbound continuará responsável pela resolução recursiva na **porta 5335**;
- o sistema operacional continuará utilizando o Unbound através do `systemd-resolved`;
- não será necessária qualquer reconfiguração do Unbound após a instalação do Pi-hole.
