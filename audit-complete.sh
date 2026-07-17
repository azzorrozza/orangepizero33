#!/usr/bin/env bash

###############################################################################
# OrangePi Auditor
#
# Auditoria completa para:
# - Armbian
# - Tailscale
# - Unbound
# - Docker CE
# - Portainer
# - Pi-hole
# - MySpeed
###############################################################################

set +e

FAIL=0
VERBOSE=0

[[ "$1" == "--verbose" ]] && VERBOSE=1
#
###############################################################################

set +e

FAIL=0
VERBOSE=0

[[ "$1" == "--verbose" ]] && VERBOSE=1

###############################################################################
# Funções
###############################################################################

ok() {
    if [[ "$VERBOSE" == "1" ]]; then
        printf "[ OK ] %s\n" "$1"
    fi
}

fail() {
    printf "[FAIL] %s\n" "$1"
    FAIL=1
}

check_cmd() {
    local DESC="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        ok "$DESC"
    else
        fail "$DESC"
    fi
}

check_pipe() {
    local DESC="$1"
    shift

    if bash -c "$*" >/dev/null 2>&1; then
        ok "$DESC"
    else
        fail "$DESC"
    fi
}

check_file() {
    local DESC="$1"
    local FILE="$2"

    if [[ -f "$FILE" ]]; then
        ok "$DESC"
    else
        fail "$DESC"
    fi
}

###############################################################################
# Banner
###############################################################################

echo
echo "========================================================"
echo " OrangePi Auditor v1.1"
echo "========================================================"
echo "Host : $(hostname)"
echo "Date : $(date)"
echo "Kernel : $(uname -r)"
echo

###############################################################################
# Sistema
###############################################################################

if systemctl --failed --no-legend | grep -q .; then
    fail "Existem serviços em falha"
else
    ok "Nenhum serviço em falha"
fi

###############################################################################
# IPv4 / IPv6 Forward
###############################################################################

check_pipe \
"IPv4 Forward" \
'[[ "$(sysctl -n net.ipv4.ip_forward)" == "1" ]]'

check_pipe \
"IPv6 Forward" \
'[[ "$(sysctl -n net.ipv6.conf.all.forwarding)" == "1" ]]'

###############################################################################
# Tailscale
###############################################################################

check_cmd \
"Serviço tailscaled" \
systemctl is-active tailscaled

check_pipe \
"Exit Node habilitado" \
'tailscale status --self | grep -qi "offers exit node"'

check_pipe \
"Tailscale IPv4" \
'tailscale ip -4 | grep -q .'

check_pipe \
"Tailscale IPv6" \
'tailscale ip -6 | grep -q .'

check_pipe \
"Versão do Tailscale" \
'tailscale version | head -1 | grep -q .'

check_pipe \
"Status do Tailscale" \
'tailscale status --self | grep -q "$(hostname)"'

###############################################################################
# UDP GRO
###############################################################################

check_pipe \
"UDP GRO habilitado" \
'ethtool -k end0 | grep -q "generic-receive-offload: on"'

###############################################################################
# networkd-dispatcher
###############################################################################

check_cmd \
"networkd-dispatcher ativo" \
systemctl is-active networkd-dispatcher

check_pipe \
"Script Subnet Router existe" \
'test -f /etc/networkd-dispatcher/routable.d/50-tailscale-route'

check_pipe \
"Script Subnet Router válido" \
'bash -n /etc/networkd-dispatcher/routable.d/50-tailscale-route'

###############################################################################
# systemd-resolved
###############################################################################

check_cmd \
"systemd-resolved ativo" \
systemctl is-active systemd-resolved

check_pipe \
"DNS=127.0.0.1" \
'grep -q "^DNS=127.0.0.1" /etc/systemd/resolved.conf'

check_pipe \
"DNSStubListener=no" \
'grep -q "^DNSStubListener=no" /etc/systemd/resolved.conf'

check_pipe \
"/etc/resolv.conf usa localhost" \
'grep -q "^nameserver 127.0.0.1" /etc/resolv.conf'

###############################################################################
# Netplan
###############################################################################

check_cmd \
"Netplan instalado" \
netplan get

check_pipe \
"Arquivo Netplan existe" \
'ls /etc/netplan/*.yaml >/dev/null 2>&1'

###############################################################################
# Unbound
###############################################################################

check_cmd \
"Serviço Unbound ativo" \
systemctl is-active unbound

check_cmd \
"Configuração Unbound válida" \
unbound-checkconf

check_pipe \
"Interface Unbound = 0.0.0.0" \
'unbound-checkconf -o interface | grep -q "0.0.0.0"'

check_pipe \
"Porta Unbound = 5335" \
'unbound-checkconf -o port | grep -q "^5335$"'

###############################################################################
# Trust Anchor
###############################################################################

check_file \
"root.key presente" \
"/var/lib/unbound/root.key"

###############################################################################
# DNS
###############################################################################

check_pipe \
"Unbound responde OpenAI" \
'dig @127.0.0.1 -p 5335 openai.com +short | grep -q .'

check_pipe \
"Unbound responde Cloudflare" \
'dig @127.0.0.1 -p 5335 cloudflare.com +short | grep -q .'

check_pipe \
"DNSSEC funcionando" \
'dig @127.0.0.1 -p 5335 dnssec-failed.org | grep -q SERVFAIL'

check_pipe \
"DNS LAN responde" \
'dig @"$(hostname -I | awk "{print \$1}")" -p 5335 openai.com +short | grep -q .'

###############################################################################
# Cache Unbound
###############################################################################

check_pipe \
"Cache Unbound disponível" \
'unbound-control stats_noreset | grep -q cache'

###############################################################################
# Docker CE
###############################################################################

check_cmd \
"Docker ativo" \
systemctl is-active docker

check_cmd \
"Docker habilitado no boot" \
systemctl is-enabled docker

check_pipe \
"Docker Engine instalado" \
'docker --version | grep -q "Docker version"'

check_pipe \
"Docker Compose instalado" \
'docker compose version | grep -q "Docker Compose"'

check_pipe \
"Containerd instalado" \
'docker info | grep -q "containerd"'

###############################################################################
# Docker Network
###############################################################################

check_pipe \
"Network services existe" \
'docker network ls | grep -q "services"'

###############################################################################
# Containers
###############################################################################

check_pipe \
"Containers em execução" \
'docker ps | tail -n +2 | grep -q .'

###############################################################################
# Portainer
###############################################################################

check_pipe \
"Container Portainer ativo" \
'docker ps --format "{{.Names}}" | grep -qx "portainer"'

check_pipe \
"Portainer saudável" \
'docker ps --format "{{.Names}} {{.Status}}" | grep -q "^portainer .*Up"'

check_pipe \
"Portainer conectado à network services" \
'docker inspect portainer | grep -q "\"services\""'

###############################################################################
# Pi-hole
###############################################################################

check_pipe \
"Container Pi-hole ativo" \
'docker ps --format "{{.Names}}" | grep -qx "pihole"'

check_pipe \
"Pi-hole Healthy" \
'docker ps --format "{{.Names}} {{.Status}}" | grep -q "^pihole .*healthy"'

check_cmd \
"Pi-hole operacional" \
docker exec pihole pihole status

check_pipe \
"Gravity DB existe" \
'docker exec pihole test -f /etc/pihole/gravity.db'

check_pipe \
"Upstream = Unbound" \
'docker exec pihole pihole-FTL --config dns.upstreams | grep -q "127.0.0.1#5335"'

###############################################################################
# DNS via Pi-hole
###############################################################################

check_pipe \
"DNS localhost responde" \
'dig @127.0.0.1 openai.com +short | grep -q .'

check_pipe \
"DNS LAN responde" \
'dig @"$(hostname -I | awk '\''{print $1}'\'')" openai.com +short | grep -q .'

###############################################################################
# Cache Unbound
###############################################################################

check_pipe \
"Cache Unbound disponível" \
'unbound-control stats_noreset | grep -q cache'

###############################################################################
# MySpeed
###############################################################################

check_pipe \
"Container MySpeed ativo" \
'docker ps --format "{{.Names}}" | grep -qx "myspeed"'

check_pipe \
"MySpeed em execução" \
'docker ps --format "{{.Names}} {{.Status}}" | grep -q "^myspeed .*Up"'

###############################################################################
# Docker Compose
###############################################################################

check_pipe \
"Docker Compose possui projetos" \
'docker compose ls | tail -n +2 | grep -q .'

###############################################################################
# Docker Storage
###############################################################################

check_pipe \
"Docker Root Dir disponível" \
'docker info | grep -q "Docker Root Dir"'

check_pipe \
"Uso do Docker obtido" \
'docker system df >/dev/null'

###############################################################################
# Arquivos Compose
###############################################################################

check_file \
"Compose Portainer" \
"/opt/docker/portainer/docker-compose.yml"

check_file \
"Compose Pi-hole" \
"/opt/docker/pihole/docker-compose.yml"

check_file \
"Compose MySpeed" \
"/opt/docker/myspeed/docker-compose.yml"


###############################################################################
# Firewall
###############################################################################

check_cmd \
"iptables funcional" \
iptables -L

check_cmd \
"ip6tables funcional" \
ip6tables -L

###############################################################################
# Portas
###############################################################################

check_pipe \
"Porta 53 TCP" \
'ss -lnpt | grep -q ":53 "'

check_pipe \
"Porta 53 UDP" \
'ss -lnpu | grep -q ":53 "'

check_pipe \
"Porta 80 HTTP" \
'ss -lnpt | grep -q ":80 "'

check_pipe \
"Porta 5335 TCP" \
'ss -lnpt | grep -q ":5335 "'

check_pipe \
"Porta 5335 UDP" \
'ss -lnpu | grep -q ":5335 "'

check_pipe \
"Porta 9443 HTTPS Portainer" \
'ss -lnpt | grep -q ":9443 "'

check_pipe \
"Porta 8000 Edge Agent" \
'ss -lnpt | grep -q ":8000 "'

check_pipe \
"Porta 5216 MySpeed" \
'ss -lnpt | grep -q ":5216 "'

###############################################################################
# Recursos do Sistema
###############################################################################

check_pipe \
"Uso do disco abaixo de 90%" \
'df / | awk '\''NR==2{exit ($5+0<90)?0:1}'\'''

check_pipe \
"Memória disponível" \
'free -m | awk '\''NR==2{exit ($7>128)?0:1}'\'''

check_pipe \
"Carga do sistema disponível" \
'uptime | grep -q "load average"'

###############################################################################
# Inicialização
###############################################################################

check_cmd \
"systemd-analyze" \
systemd-analyze blame

###############################################################################
# Informações extras (--verbose)
###############################################################################

if [[ "$VERBOSE" == "1" ]]; then

echo
echo "==================== RESUMO ===================="

echo
echo "Hostname"
hostname

echo
echo "Sistema"
uname -a

echo
echo "Endereços IP"
hostname -I

echo
echo "Containers"
docker ps

echo
echo "Docker Compose"
docker compose ls

echo
echo "Tailscale"
tailscale status --self

echo
echo "DNS Upstream"
docker exec pihole pihole-FTL --config dns.upstreams

echo
echo "Uso de Disco"
df -h /

echo
echo "Memória"
free -h

echo
echo "Uptime"
uptime

fi

###############################################################################
# Resultado Final
###############################################################################

echo
echo "========================================================"

if [[ "$FAIL" -eq 0 ]]; then
    echo "               status: NOERROR"
else
    echo "                status: ERROR"
fi

echo "========================================================"

exit "$FAIL"
```
