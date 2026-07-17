# Auditoria Completa - OrangePi Zero 3

## Objetivo

Executar uma validação completa de:

- Sistema
- Rede
- Tailscale
- Subnet Router
- UDP GRO
- systemd-resolved
- Netplan
- Unbound
- DNSSEC
- Docker
- Portainer
- Pi-hole
- MySpeed
- Firewall
- Recursos do sistema

---

## Como executar

Execute tudo de uma vez:

```bash
bash <<'EOF'
#!/usr/bin/env bash

FAIL=0

ok()   { echo "[ OK ] $1"; }
warn() { echo "[FAIL] $1"; FAIL=1; }

echo
echo "========== OrangePi Auditor =========="
echo

########################################
# Sistema
########################################

systemctl --failed --no-legend | grep -q .

if [ $? -eq 0 ]; then
    warn "Existem serviços em falha"
else
    ok "Nenhum serviço em falha"
fi

########################################
# IP Forward
########################################

[ "$(sysctl -n net.ipv4.ip_forward)" = "1" ] \
&& ok "IPv4 Forward" \
|| warn "IPv4 Forward"

[ "$(sysctl -n net.ipv6.conf.all.forwarding)" = "1" ] \
&& ok "IPv6 Forward" \
|| warn "IPv6 Forward"

########################################
# Tailscale
########################################

systemctl is-active tailscaled >/dev/null \
&& ok "tailscaled ativo" \
|| warn "tailscaled"

tailscale status --self | grep -qi "offers exit node" \
&& ok "Exit Node anunciado" \
|| warn "Exit Node"

tailscale ip >/dev/null \
&& ok "Tailscale IP" \
|| warn "Tailscale IP"

########################################
# UDP GRO
########################################

ethtool -k end0 | grep -q "generic-receive-offload: on" \
&& ok "UDP GRO" \
|| warn "UDP GRO"

########################################
# networkd-dispatcher
########################################

systemctl is-active networkd-dispatcher >/dev/null \
&& ok "networkd-dispatcher" \
|| warn "networkd-dispatcher"

########################################
# systemd-resolved
########################################

grep -q '^DNS=127.0.0.1' /etc/systemd/resolved.conf \
&& ok "resolved.conf DNS" \
|| warn "resolved.conf DNS"

grep -q '^DNSStubListener=no' /etc/systemd/resolved.conf \
&& ok "DNSStubListener" \
|| warn "DNSStubListener"

grep -q "nameserver 127.0.0.1" /etc/resolv.conf \
&& ok "resolv.conf" \
|| warn "resolv.conf"

########################################
# Netplan
########################################

netplan get >/dev/null 2>&1 \
&& ok "Netplan" \
|| warn "Netplan"

########################################
# Unbound
########################################

systemctl is-active unbound >/dev/null \
&& ok "Unbound ativo" \
|| warn "Unbound"

unbound-checkconf >/dev/null 2>&1 \
&& ok "Configuração Unbound" \
|| warn "Configuração Unbound"

dig @127.0.0.1 -p 5335 openai.com +short | grep -q . \
&& ok "Resolução Unbound" \
|| warn "Resolução Unbound"

dig @127.0.0.1 -p 5335 dnssec-failed.org \
| grep -q SERVFAIL \
&& ok "DNSSEC" \
|| warn "DNSSEC"

########################################
# Docker
########################################

systemctl is-active docker >/dev/null \
&& ok "Docker ativo" \
|| warn "Docker"

docker compose version >/dev/null 2>&1 \
&& ok "Docker Compose" \
|| warn "Docker Compose"

########################################
# Portainer
########################################

docker ps --format '{{.Names}} {{.Status}}' \
| grep -q '^portainer .*Up' \
&& ok "Portainer" \
|| warn "Portainer"

########################################
# Pi-hole
########################################

docker ps --format '{{.Names}} {{.Status}}' \
| grep -q '^pihole .*healthy' \
&& ok "Pi-hole Healthy" \
|| warn "Pi-hole Healthy"

docker exec pihole pihole status >/dev/null 2>&1 \
&& ok "Pi-hole Status" \
|| warn "Pi-hole Status"

docker exec pihole pihole-FTL --config dns.upstreams \
| grep -q "127.0.0.1#5335" \
&& ok "Upstream Pi-hole" \
|| warn "Upstream Pi-hole"

docker exec pihole test -f /etc/pihole/gravity.db \
&& ok "Gravity DB" \
|| warn "Gravity DB"

dig @127.0.0.1 openai.com +short | grep -q . \
&& ok "DNS localhost"

dig @"$(hostname -I | awk '{print $1}')" openai.com +short | grep -q . \
&& ok "DNS LAN" \
|| warn "DNS LAN"

########################################
# Cache Unbound
########################################

unbound-control stats_noreset 2>/dev/null \
| grep -q cache \
&& ok "Cache Unbound" \
|| warn "Cache Unbound"

########################################
# MySpeed
########################################

docker ps --format '{{.Names}} {{.Status}}' \
| grep -q '^myspeed .*Up' \
&& ok "MySpeed" \
|| warn "MySpeed"

########################################
# Firewall
########################################

iptables -L >/dev/null 2>&1 \
&& ok "iptables" \
|| warn "iptables"

ip6tables -L >/dev/null 2>&1 \
&& ok "ip6tables" \
|| warn "ip6tables"

########################################
# Portas
########################################

ss -lnptu | grep -q ':53 ' \
&& ok "Porta 53" \
|| warn "Porta 53"

ss -lnptu | grep -q ':5335 ' \
&& ok "Porta 5335" \
|| warn "Porta 5335"

ss -lnptu | grep -q ':9443 ' \
&& ok "Porta 9443" \
|| warn "Porta 9443"

########################################
# Recursos
########################################

df / | awk 'NR==2{if($5+0<90) exit 0; else exit 1}'

if [ $? -eq 0 ]; then
    ok "Espaço em disco"
else
    warn "Disco quase cheio"
fi

########################################

echo
echo "====================================="

if [ $FAIL -eq 0 ]; then
    echo
    echo "status: NOERROR"
else
    echo
    echo "status: ERROR"
fi

echo "====================================="
EOF
```

---

## Resultado esperado

Se tudo estiver correto, o retorno será semelhante a:

```text
[ OK ] Nenhum serviço em falha
[ OK ] IPv4 Forward
[ OK ] IPv6 Forward
[ OK ] tailscaled ativo
[ OK ] Exit Node anunciado
[ OK ] UDP GRO
[ OK ] networkd-dispatcher
[ OK ] resolved.conf DNS
[ OK ] DNSStubListener
[ OK ] resolv.conf
[ OK ] Netplan
[ OK ] Unbound ativo
[ OK ] Configuração Unbound
[ OK ] Resolução Unbound
[ OK ] DNSSEC
[ OK ] Docker ativo
[ OK ] Docker Compose
[ OK ] Portainer
[ OK ] Pi-hole Healthy
[ OK ] Pi-hole Status
[ OK ] Upstream Pi-hole
[ OK ] Gravity DB
[ OK ] DNS localhost
[ OK ] DNS LAN
[ OK ] Cache Unbound
[ OK ] MySpeed
[ OK ] iptables
[ OK ] ip6tables
[ OK ] Porta 53
[ OK ] Porta 5335
[ OK ] Porta 9443
[ OK ] Espaço em disco

status: NOERROR
```

Caso exista qualquer problema, **apenas as linhas com `[FAIL]` aparecerão**, seguidas de:

```text
status: ERROR
```

Assim você pode simplesmente copiar e colar toda a saída aqui que eu consigo identificar rapidamente qualquer inconsistência.
