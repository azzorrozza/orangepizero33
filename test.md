# OrangePi Zero 3 - Validação do Sistema

```

#Sistema
cat /etc/os-release
uname -a

df -h
free -h

# Rede
ip addr show end0
ip route
resolvectl status

sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding

# Tailscale
tailscale status
tailscale debug prefs
tailscale netcheck
tailscale ip

# Serviços
systemctl --failed
systemctl is-active tailscaled
systemctl is-enabled tailscaled
systemctl is-enabled networkd-dispatcher
systemctl is-enabled ethtool-end0.service

# Unbound
systemctl status unbound --no-pager
systemctl status systemd-resolved --no-pager

journalctl -u networkd-dispatcher -b --no-pager | tail -30

ethtool -k end0 | grep udp

unbound-checkconf
unbound-checkconf -o interface
unbound-checkconf -o port

ss -lnptu | grep :53

ls -l /var/lib/unbound/root.key

/usr/libexec/unbound-helper root_trust_anchor_update
echo $?

dig @127.0.0.1 openai.com
dig @192.168.1.20 openai.com
dig @127.0.0.1 dnssec-failed.org
dig @127.0.0.1 cloudflare.com +dnssec

resolvectl query openai.com

unbound-control stats_noreset

# Docker
docker --version
docker compose version
docker info

docker images
docker ps -a
docker volume ls

docker compose ls

docker network ls
docker network inspect services

docker run --rm hello-world

systemctl is-enabled docker
systemctl is-active docker
systemctl status docker --no-pager

# Portainer
docker logs portainer
curl -I -k https://localhost:9443

tree /opt/docker

cat /opt/docker/portainer/docker-compose.yml

```
