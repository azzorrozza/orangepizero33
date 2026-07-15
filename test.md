# OrangePi Zero 3 - Validação do Sistema

## Sistema

```bash
cat /etc/os-release

uname -a

apt update

apt list --upgradable

df -h

free -h
```

## Rede

```bash
ip addr show end0

ip route

resolvectl status

cat /etc/netplan/*.yaml
```

## IP Forwarding

```bash
sysctl net.ipv4.ip_forward

sysctl net.ipv6.conf.all.forwarding
```

## Tailscale

```bash
tailscale status

tailscale debug prefs

tailscale netcheck

tailscale ip
```

## Serviços

```bash
systemctl is-active tailscaled

systemctl is-enabled tailscaled

systemctl is-enabled networkd-dispatcher

systemctl is-enabled ethtool-end0.service

systemctl status unbound --no-pager

systemctl status systemd-resolved --no-pager
```

## UDP GRO

```bash
ethtool -k end0 | grep udp
```

## Network Dispatcher

```bash
journalctl -u networkd-dispatcher -b

cat /etc/networkd-dispatcher/routable.d/50-tailscale-route
```

## Unbound

```bash
unbound-checkconf

unbound-checkconf -o interface

unbound-checkconf -o port

ss -lnptu | grep :53

ls -l /var/lib/unbound/root.key

/usr/libexec/unbound-helper root_trust_anchor_update

echo $?
```

## DNS

```bash
dig @127.0.0.1 openai.com

dig @192.168.1.20 openai.com

dig @192.168.1.20 openai.com

dig @127.0.0.1 dnssec-failed.org

dig @127.0.0.1 cloudflare.com +dnssec

resolvectl query openai.com
```

## Estatísticas

```bash
unbound-control stats_noreset
```

## Após reiniciar

```bash
reboot
```

Após reconectar via SSH:

```bash
systemctl --failed

tailscale status

systemctl status unbound --no-pager

systemctl status systemd-resolved --no-pager

ethtool -k end0 | grep udp

ss -lnptu | grep :53

dig @127.0.0.1 openai.com

dig @127.0.0.1 dnssec-failed.org

unbound-control stats_noreset
```
