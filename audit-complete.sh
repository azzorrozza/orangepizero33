#!/usr/bin/env bash

###############################################################################
# OrangePi Auditor v2.0
#
# Auditoria completa para:
#
#  - Armbian
#  - Tailscale
#  - Exit Node
#  - Subnet Router
#  - UDP GRO
#  - networkd-dispatcher
#  - systemd-resolved
#  - Netplan
#  - Unbound
#  - DNSSEC
#  - Docker CE
#  - Portainer
#  - Pi-hole
#  - MySpeed
#
###############################################################################

set +e

VERSION="2.0"

VERBOSE=0
[[ "$1" == "--verbose" ]] && VERBOSE=1

FAIL=0
TOTAL=0
PASS=0

###############################################################################
# Colors
###############################################################################

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

###############################################################################
# Counters
###############################################################################

pass() {

    ((TOTAL++))
    ((PASS++))

    if [[ "$VERBOSE" == "1" ]]; then
        printf "${GREEN}[ OK ]${RESET} %s\n" "$1"
    fi

}

fail() {

    ((TOTAL++))
    FAIL=1

    printf "${RED}[FAIL]${RESET} %s\n" "$1"

}

###############################################################################
# Helpers
###############################################################################

check_cmd() {

    local DESC="$1"
    shift

    if "$@" >/dev/null 2>&1
    then
        pass "$DESC"
    else
        fail "$DESC"
    fi

}

check_pipe() {

    local DESC="$1"
    shift

    if bash -c "$*" >/dev/null 2>&1
    then
        pass "$DESC"
    else
        fail "$DESC"
    fi

}

check_file() {

    local DESC="$1"
    local FILE="$2"

    if [[ -f "$FILE" ]]
    then
        pass "$DESC"
    else
        fail "$DESC"
    fi

}

check_dir() {

    local DESC="$1"
    local DIR="$2"

    if [[ -d "$DIR" ]]
    then
        pass "$DESC"
    else
        fail "$DESC"
    fi

}

section() {

    echo
    echo "###############################################################################"
    echo "# $1"
    echo "###############################################################################"

}

###############################################################################
# Banner
###############################################################################

echo
echo "======================================================================="
echo "                 OrangePi Auditor v${VERSION}"
echo "======================================================================="
echo "Hostname : $(hostname)"
echo "Date     : $(date)"
echo "Kernel   : $(uname -r)"
echo "======================================================================="

###############################################################################
# Sistema
###############################################################################

section "Sistema"

if systemctl --failed --no-legend | grep -q .
then
    fail "Existem serviços em falha"
else
    pass "Nenhum serviço em falha"
fi

check_cmd \
"systemd-analyze" \
systemd-analyze blame

check_pipe \
"Carga do sistema" \
'uptime | grep -q "load average"'

check_pipe \
"Uso do disco < 90%" \
'df / | awk '\''NR==2{exit ($5+0<90)?0:1}'\'''

check_pipe \
"Memória disponível" \
'free -m | awk '\''NR==2{exit ($7>128)?0:1}'\'''

###############################################################################
# IPv4 / IPv6
###############################################################################

section "IPv4 / IPv6"

check_pipe \
"IPv4 Forward" \
'[[ "$(sysctl -n net.ipv4.ip_forward)" == "1" ]]'

check_pipe \
"IPv6 Forward" \
'[[ "$(sysctl -n net.ipv6.conf.all.forwarding)" == "1" ]]'

check_pipe \
"Arquivo 99-tailscale.conf existe" \
'test -f /etc/sysctl.d/99-tailscale.conf'

check_pipe \
"99-tailscale.conf possui IPv4 Forward" \
'grep -q "^net.ipv4.ip_forward *= *1" /etc/sysctl.d/99-tailscale.conf'

check_pipe \
"99-tailscale.conf possui IPv6 Forward" \
'grep -q "^net.ipv6.conf.all.forwarding *= *1" /etc/sysctl.d/99-tailscale.conf'

###############################################################################
# Tailscale
###############################################################################

section "Tailscale"

check_cmd \
"tailscaled ativo" \
systemctl is-active tailscaled

check_cmd \
"tailscaled habilitado no boot" \
systemctl is-enabled tailscaled

check_pipe \
"Tailscale instalado" \
'tailscale version | head -1 | grep -q .'

check_pipe \
"Tailscale IPv4" \
'tailscale ip -4 | grep -q .'

check_pipe \
"Tailscale IPv6" \
'tailscale ip -6 | grep -q .'

check_pipe \
"Hostname registrado" \
'tailscale status --self | grep -q "$(hostname)"'

check_pipe \
"Exit Node habilitado" \
'tailscale status --self | grep -qi "offers exit node"'

check_pipe \
"Accept Routes habilitado" \
'tailscale debug prefs | jq -e ".RouteAll == true" >/dev/null'

check_pipe \
"Advertise Routes configurado" \
'tailscale debug prefs | jq -e ".AdvertiseRoutes | length > 0" >/dev/null'

check_pipe \
"Subnet Router ativo" \
'tailscale debug prefs | jq -r ".AdvertiseRoutes[]" | grep -q "/"'

###############################################################################
# UDP GRO
###############################################################################

section "UDP GRO"

check_pipe \
"generic-receive-offload ligado" \
'ethtool -k end0 | grep -q "generic-receive-offload: on"'

check_pipe \
"rx-udp-gro-forwarding ligado" \
'ethtool -k end0 | grep -q "rx-udp-gro-forwarding: on"'

check_cmd \
"Serviço ethtool-end0 ativo" \
systemctl is-active ethtool-end0.service

check_cmd \
"Serviço ethtool-end0 habilitado" \
systemctl is-enabled ethtool-end0.service

check_file \
"Arquivo ethtool-end0.service" \
"/etc/systemd/system/ethtool-end0.service"

###############################################################################
# networkd-dispatcher
###############################################################################

section "networkd-dispatcher"

check_cmd \
"Serviço ativo" \
systemctl is-active networkd-dispatcher

check_cmd \
"Serviço habilitado" \
systemctl is-enabled networkd-dispatcher

check_file \
"Script 50-tailscale-route existe" \
"/etc/networkd-dispatcher/routable.d/50-tailscale-route"

check_pipe \
"Script possui sintaxe válida" \
'bash -n /etc/networkd-dispatcher/routable.d/50-tailscale-route'

check_pipe \
"Script anuncia Exit Node" \
'grep -q -- "--advertise-exit-node" /etc/networkd-dispatcher/routable.d/50-tailscale-route'

check_pipe \
"Script aceita rotas" \
'grep -q -- "--accept-routes" /etc/networkd-dispatcher/routable.d/50-tailscale-route'

###############################################################################
# systemd-resolved
###############################################################################

section "systemd-resolved"

check_cmd \
"systemd-resolved ativo" \
systemctl is-active systemd-resolved

check_cmd \
"systemd-resolved habilitado" \
systemctl is-enabled systemd-resolved

check_pipe \
"resolved.conf existe" \
'test -f /etc/systemd/resolved.conf'

check_pipe \
"DNS=127.0.0.1 configurado" \
'grep -q "^DNS=127.0.0.1" /etc/systemd/resolved.conf'

check_pipe \
"DNSStubListener=no" \
'grep -q "^DNSStubListener=no" /etc/systemd/resolved.conf'

check_pipe \
"/etc/resolv.conf aponta para localhost" \
'grep -q "^nameserver 127.0.0.1" /etc/resolv.conf'

###############################################################################
# Netplan
###############################################################################

section "Netplan"

check_pipe \
"Netplan instalado" \
'command -v netplan >/dev/null'

check_pipe \
"Arquivo YAML existe" \
'ls /etc/netplan/*.yaml >/dev/null 2>&1'

check_pipe \
"Configuração válida" \
'netplan generate >/dev/null 2>&1'

check_pipe \
"Renderer = networkd" \
'grep -R "renderer: networkd" /etc/netplan/*.yaml >/dev/null'

check_pipe \
"use-dns=false DHCPv4" \
'awk "
/dhcp4-overrides:/ {f=1; next}
f && /use-dns:[[:space:]]*false/ {ok=1; exit}
f && /^[^[:space:]]/ {f=0}
END {exit ok?0:1}
" /etc/netplan/*.yaml'

check_pipe \
"use-dns=false DHCPv6" \
'awk "
/dhcp6-overrides:/ {f=1; next}
f && /use-dns:[[:space:]]*false/ {ok=1; exit}
f && /^[^[:space:]]/ {f=0}
END {exit ok?0:1}
" /etc/netplan/*.yaml'

###############################################################################
# Unbound
###############################################################################

section "Unbound"

check_cmd \
"Serviço ativo" \
systemctl is-active unbound

check_cmd \
"Serviço habilitado" \
systemctl is-enabled unbound

check_cmd \
"Configuração válida" \
unbound-checkconf

check_file \
"recursive.conf existe" \
"/etc/unbound/unbound.conf.d/recursive.conf"

check_pipe \
"Interface IPv4 = 0.0.0.0" \
'unbound-checkconf -o interface | grep -q "0.0.0.0"'

check_pipe \
"Interface IPv6 = ::0" \
'unbound-checkconf -o interface | grep -q "::0"'

check_pipe \
"Porta = 5335" \
'unbound-checkconf -o port | grep -qx "5335"'

check_pipe \
"DNSSEC Validator ativo" \
'grep -q "validator iterator" /etc/unbound/unbound.conf.d/recursive.conf'

check_file \
"Trust Anchor existe" \
"/var/lib/unbound/root.key"

check_pipe \
"unbound-resolvconf mascarado" \
'systemctl is-enabled unbound-resolvconf.service 2>/dev/null | grep -q masked'

###############################################################################
# DNS
###############################################################################

section "DNS"

LAN_IP="$(hostname -I | awk "{print \$1}")"

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
'dig @"'"$LAN_IP"'" -p 5335 openai.com +short | grep -q .'

check_pipe \
"Cache Unbound disponível" \
'unbound-control stats_noreset | grep -q cache'

###############################################################################
# Docker
###############################################################################

section "Docker"

check_cmd \
"Docker ativo" \
systemctl is-active docker

check_cmd \
"Docker habilitado" \
systemctl is-enabled docker

check_pipe \
"Docker Engine instalado" \
'docker --version | grep -q "Docker version"'

check_pipe \
"Docker Compose instalado" \
'docker compose version | grep -q "Docker Compose"'

check_pipe \
"Containerd instalado" \
'docker info | grep -q containerd'

check_pipe \
"Diretório /opt/docker existe" \
'test -d /opt/docker'

check_pipe \
"Rede services existe" \
'docker network ls | grep -qw services'

check_pipe \
"Projetos Compose encontrados" \
'docker compose ls | tail -n +2 | grep -q .'

check_pipe \
"Docker Root Dir disponível" \
'docker info | grep -q "Docker Root Dir"'

check_pipe \
"docker system df funciona" \
'docker system df >/dev/null'

###############################################################################
# Portainer
###############################################################################

section "Portainer"

check_file \
"docker-compose.yml" \
"/opt/docker/portainer/docker-compose.yml"

check_pipe \
"Container ativo" \
'docker ps --format "{{.Names}}" | grep -qx portainer'

check_pipe \
"Container saudável" \
'docker ps --format "{{.Names}} {{.Status}}" | grep -q "^portainer .*Up"'

check_pipe \
"Conectado à network services" \
'docker inspect portainer | grep -q "\"services\""'

check_pipe \
"Porta 9443 publicada" \
'ss -lnpt | grep -q ":9443 "'

check_pipe \
"Porta 8000 publicada" \
'ss -lnpt | grep -q ":8000 "'

###############################################################################
# Pi-hole
###############################################################################

section "Pi-hole"

check_file \
"docker-compose.yml" \
"/opt/docker/pihole/docker-compose.yml"

check_pipe \
"Container ativo" \
'docker ps --format "{{.Names}}" | grep -qx pihole'

check_pipe \
"Container Healthy" \
'docker ps --format "{{.Names}} {{.Status}}" | grep -q "^pihole .*healthy"'

check_cmd \
"Pi-hole operacional" \
docker exec pihole pihole status

check_pipe \
"Gravity DB existe" \
'docker exec pihole test -f /etc/pihole/gravity.db'

check_pipe \
"Diretório /etc/pihole montado" \
'docker inspect pihole | grep -q "/etc/pihole"'

check_pipe \
"Diretório /etc/dnsmasq.d montado" \
'docker inspect pihole | grep -q "/etc/dnsmasq.d"'

check_pipe \
"Hostname configurado" \
'docker inspect pihole | grep -q "\"Hostname\": \"orangepi\""'

check_pipe \
"Modo Host habilitado" \
'docker inspect pihole | grep -q "\"NetworkMode\": \"host\""'

check_pipe \
"Restart Policy unless-stopped" \
'docker inspect pihole | grep -q "\"Name\": \"unless-stopped\""'

check_pipe \
"Timezone configurado" \
'docker exec pihole printenv TZ | grep -q "America/Sao_Paulo"'

check_pipe \
"Listening Mode = all" \
'docker exec pihole pihole-FTL --config dns.listeningMode | grep -qi "all"'

check_pipe \
"Upstream = Unbound" \
'docker exec pihole pihole-FTL --config dns.upstreams | grep -q "127.0.0.1#5335"'

check_pipe \
"Bootstrap DNS removido" \
'! grep -q "^ *dns:" /opt/docker/pihole/docker-compose.yml'

check_pipe \
"dns_search removido" \
'! grep -q "^ *dns_search:" /opt/docker/pihole/docker-compose.yml'

###############################################################################
# DNS via Pi-hole
###############################################################################

section "DNS via Pi-hole"

check_pipe \
"DNS localhost responde" \
'dig @127.0.0.1 openai.com +short | grep -q .'

check_pipe \
"DNS LAN responde" \
'dig @"'"$LAN_IP"'" openai.com +short | grep -q .'

check_pipe \
"Cloudflare responde" \
'dig @127.0.0.1 cloudflare.com +short | grep -q .'

check_pipe \
"DNSSEC continua ativo" \
'dig @127.0.0.1 dnssec-failed.org | grep -q SERVFAIL'

###############################################################################
# MySpeed
###############################################################################

section "MySpeed"

check_file \
"docker-compose.yml" \
"/opt/docker/myspeed/docker-compose.yml"

check_pipe \
"Container ativo" \
'docker ps --format "{{.Names}}" | grep -qx myspeed'

check_pipe \
"Container em execução" \
'docker ps --format "{{.Names}} {{.Status}}" | grep -q "^myspeed .*Up"'

check_pipe \
"Restart Policy unless-stopped" \
'docker inspect myspeed | grep -q "\"Name\": \"unless-stopped\""'

check_pipe \
"Volume persistente configurado" \
'docker inspect myspeed | grep -q "/myspeed/data"'

check_pipe \
"Conectado à network services" \
'docker inspect myspeed | grep -q "\"services\""'

check_pipe \
"Porta 5216 publicada" \
'ss -lnpt | grep -q ":5216 "'

###############################################################################
# Firewall
###############################################################################

section "Firewall"

check_cmd \
"iptables funcional" \
iptables -L

check_cmd \
"ip6tables funcional" \
ip6tables -L

###############################################################################
# Portas
###############################################################################

section "Portas"

check_pipe \
"53/TCP" \
'ss -lnpt | grep -q ":53 "'

check_pipe \
"53/UDP" \
'ss -lnpu | grep -q ":53 "'

check_pipe \
"80/TCP" \
'ss -lnpt | grep -q ":80 "'

check_pipe \
"5335/TCP" \
'ss -lnpt | grep -q ":5335 "'

check_pipe \
"5335/UDP" \
'ss -lnpu | grep -q ":5335 "'

check_pipe \
"9443/TCP" \
'ss -lnpt | grep -q ":9443 "'

check_pipe \
"8000/TCP" \
'ss -lnpt | grep -q ":8000 "'

check_pipe \
"5216/TCP" \
'ss -lnpt | grep -q ":5216 "'

###############################################################################
# Docker Compose
###############################################################################

section "Docker Compose"

check_pipe \
"Projeto Portainer encontrado" \
'docker compose ls | grep -qw portainer'

check_pipe \
"Projeto Pi-hole encontrado" \
'docker compose ls | grep -qw pihole'

check_pipe \
"Projeto MySpeed encontrado" \
'docker compose ls | grep -qw myspeed'

check_pipe \
"Compose Portainer presente" \
'test -f /opt/docker/portainer/docker-compose.yml'

check_pipe \
"Compose Pi-hole presente" \
'test -f /opt/docker/pihole/docker-compose.yml'

check_pipe \
"Compose MySpeed presente" \
'test -f /opt/docker/myspeed/docker-compose.yml'

###############################################################################
# Informações extras (--verbose)
###############################################################################

if [[ "$VERBOSE" == "1" ]]; then

section "Resumo"

echo
echo "Hostname"
hostname

echo
echo "Sistema"
uname -a

echo
echo "Uptime"
uptime

echo
echo "Kernel"
uname -r

echo
echo "Arquitetura"
uname -m

###############################################################################

echo
echo "Endereços IP"
hostname -I

echo
echo "Interfaces"

ip -brief address

###############################################################################

echo
echo "Uso de Disco"

df -h /

###############################################################################

echo
echo "Memória"

free -h

###############################################################################

echo
echo "CPU"

lscpu | grep -E '^Model name|^CPU\(s\)|^Thread|^Core'

###############################################################################

echo
echo "Docker"

docker ps

echo
echo "Docker Compose"

docker compose ls

echo
echo "Docker Networks"

docker network ls

###############################################################################

echo
echo "Portainer"

docker inspect portainer \
--format='Status={{.State.Status}} Restart={{.HostConfig.RestartPolicy.Name}}'

###############################################################################

echo
echo "Pi-hole"

docker inspect pihole \
--format='Status={{.State.Status}} Health={{if .State.Health}}{{.State.Health.Status}}{{end}}'

echo
echo "Pi-hole Upstream"

docker exec pihole \
pihole-FTL --config dns.upstreams

###############################################################################

echo
echo "MySpeed"

docker inspect myspeed \
--format='Status={{.State.Status}} Restart={{.HostConfig.RestartPolicy.Name}}'

###############################################################################

echo
echo "Tailscale"

tailscale status --self

echo
echo "Advertised Routes"

tailscale debug prefs \
| jq '.AdvertiseRoutes'

###############################################################################

echo
echo "Unbound"

systemctl --no-pager --plain --full status unbound \
| head -15

###############################################################################

echo
echo "DNS"

dig @127.0.0.1 openai.com +short

echo
echo "DNSSEC"

dig @127.0.0.1 dnssec-failed.org \
| grep status

###############################################################################

echo
echo "Listening Ports"

ss -lnptu

###############################################################################

fi

###############################################################################
# Resultado Final
###############################################################################

echo
echo "======================================================================="

echo
echo "Total de verificações : $TOTAL"
echo "Verificações OK       : $PASS"
echo "Falhas                : $((TOTAL-PASS))"

echo

if [[ "$FAIL" -eq 0 ]]
then

    echo -e "${GREEN}"
    echo "                     STATUS : NOERROR"
    echo -e "${RESET}"

else

    echo -e "${RED}"
    echo "                     STATUS : ERROR"
    echo -e "${RESET}"

fi

echo "======================================================================="

exit "$FAIL"
