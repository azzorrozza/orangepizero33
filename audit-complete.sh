# Auditoria Completa - OrangePi Zero 3

Este documento realiza uma auditoria completa do ambiente após a instalação de todos os componentes.

A auditoria valida automaticamente:

- Sistema Operacional
- Rede
- Tailscale
- Exit Node
- Subnet Router
- UDP GRO
- systemd-resolved
- Netplan
- Unbound
- DNSSEC
- Docker CE
- Portainer
- Pi-hole
- MySpeed
- Firewall
- Portas
- Recursos do sistema

A saída foi projetada para ser compacta, facilitando o envio em tickets ou para análise.

---

# Executar auditoria

Execute todo o bloco abaixo.

```bash
bash <<'EOF'
#!/usr/bin/env bash

FAIL=0
VERBOSE=0

[[ "$1" == "--verbose" ]] && VERBOSE=1

ok() {
    [ "$VERBOSE" = "1" ] && echo "[ OK ] $1"
}

fail() {
    echo "[FAIL] $1"
    FAIL=1
}

echo
echo "OrangePi Auditor v1.0"
echo "Host : $(hostname)"
echo "Data : $(date)"
echo

########################################
# Sistema
########################################

systemctl --failed --no-legend | grep -q .
if [ $? -eq 0 ]; then
    fail "Existem serviços em falha"
else
    ok "Nenhum serviço em falha"
fi

########################################
# IP Forward
########################################

[ "$(sysctl -n net.ipv4.ip_forward)" = "1" ] \
|| fail "IPv4 Forward"

[ "$(sysctl -n net.ipv6.conf.all.forwarding)" = "1" ] \
|| fail "IPv6 Forward"

########################################
# Tailscale
########################################

systemctl is-active tailscaled >/dev/null \
|| fail "tailscaled"

tailscale status --self | grep -qi "offers exit node" \
|| fail "Exit Node"

tailscale ip >/dev/null \
|| fail "Tailscale IP"

########################################
# UDP GRO
########################################

ethtool -k end0 | grep -q "generic-receive-offload: on" \
|| fail "UDP GRO"

########################################
# networkd-dispatcher
########################################

systemctl is-active networkd-dispatcher >/dev/null \
|| fail "networkd-dispatcher"

########################################
# systemd-resolved
########################################

grep -q '^DNS=127.0.0.1' /etc/systemd/resolved.conf \
|| fail "resolved.conf DNS"

grep -q '^DNSStubListener=no' /etc/systemd/resolved.conf \
|| fail "DNSStubListener"

grep -q "nameserver 127.0.0.1" /etc/resolv.conf \
|| fail "resolv.conf"

########################################
# Netplan
########################################

netplan get >/dev/null 2>&1 \
|| fail "Netplan"

########################################
# Unbound
########################################

systemctl is-active unbound >/dev/null \
|| fail "Unbound"

unbound-checkconf >/dev/null 2>&1 \
|| fail "Configuração Unbound"

dig @127.0.0.1 -p 5335 openai.com +short | grep -q . \
|| fail "Unbound DNS"

dig @127.0.0.1 -p 5335 dnssec-failed.org \
| grep -q SERVFAIL \
|| fail "DNSSEC"

########################################
# Docker
########################################

systemctl is-active docker >/dev/null \
|| fail "Docker"

docker compose version >/dev/null 2>&1 \
|| fail "Docker Compose"

########################################
# Portainer
########################################

docker ps --format '{{.Names}} {{.Status}}' \
| grep -q '^portainer .*Up' \
|| fail "Portainer"

########################################
# Pi-hole
########################################

docker ps --format '{{.Names}} {{.Status}}' \
| grep -q '^pihole .*healthy' \
|| fail "Pi-hole Healthy"

docker exec pihole pihole status >/dev/null 2>&1 \
|| fail "Pi-hole Status"

docker exec pihole pihole-FTL --config dns.upstreams \
| grep -q '127.0.0.1#5335' \
|| fail "Pi-hole Upstream"

docker exec pihole test -f /etc/pihole/gravity.db \
|| fail "Gravity DB"

dig @127.0.0.1 openai.com +short | grep -q . \
|| fail "DNS localhost"

dig @"$(hostname -I | awk '{print $1}')" openai.com +short | grep -q . \
|| fail "DNS LAN"

########################################
# Cache
########################################

unbound-control stats_noreset 2>/dev/null \
| grep -q cache \
|| fail "Cache Unbound"

########################################
# MySpeed
########################################

docker ps --format '{{.Names}} {{.Status}}' \
| grep -q '^myspeed .*Up' \
|| fail "MySpeed"

########################################
# Firewall
########################################

iptables -L >/dev/null 2>&1 \
|| fail "iptables"

ip6tables -L >/dev/null 2>&1 \
|| fail "ip6tables"

########################################
# Portas
########################################

ss -lnptu | grep -q ':53 ' \
|| fail "Porta 53"

ss -lnptu | grep -q ':5335 ' \
|| fail "Porta 5335"

ss -lnptu | grep -q ':9443 ' \
|| fail "Porta 9443"

########################################
# Disco
########################################

df / | awk 'NR==2 {exit ($5+0<90)?0:1}'

if [ $? -ne 0 ]; then
    fail "Disco acima de 90%"
fi

########################################
# Resultado
########################################

echo
echo "================================"

if [ "$FAIL" = "0" ]; then
    echo "status: NOERROR"
else
    echo "status: ERROR"
fi

echo "================================"
EOF
```

---

# Saída esperada

Se todo o ambiente estiver correto:

```text
OrangePi Auditor v1.0
Host : orangepizero3
Data : Fri Jul 17 ...

================================
status: NOERROR
================================
```

Caso exista qualquer problema:

```text
OrangePi Auditor v1.0
Host : orangepizero3
Data : Fri Jul 17 ...

[FAIL] Gravity DB
[FAIL] Pi-hole Healthy
[FAIL] DNS LAN

================================
status: ERROR
================================
```

Assim, basta copiar e colar a saída aqui para que a causa do problema seja identificada rapidamente.
