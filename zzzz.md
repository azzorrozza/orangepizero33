
---

```bash
apt install -y \
    unbound \
    unbound-anchor \
    dns-root-data \
    dnsutils \
    libnss-resolve
```

```bash
systemctl enable unbound
```

```bash
systemctl is-enabled unbound
```

```bash
nano /etc/systemd/resolved.conf
```

```ini
[Resolve]
DNS=127.0.0.1:5335
DNSStubListener=no
```

```bash
cat /etc/systemd/resolved.conf
```

```bash
systemctl restart systemd-resolved
```

```bash
systemctl status systemd-resolved --no-pager
```

```bash
resolvectl status
```

```bash
nano /etc/unbound/unbound.conf.d/recursive.conf
```

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

```bash
cat /etc/unbound/unbound.conf.d/recursive.conf
```

```bash
mkdir -p /var/lib/unbound
```

```bash
unbound-anchor -a /var/lib/unbound/root.key
```

```bash
chown unbound:unbound /var/lib/unbound/root.key
```

```bash
chmod 644 /var/lib/unbound/root.key
```

```bash
ls -l /var/lib/unbound/root.key
```

```bash
unbound-checkconf
```

```bash
unbound-checkconf -o interface
```

```bash
unbound-checkconf -o port
```

```bash
systemctl restart unbound
```

```bash
journalctl -u unbound -n 20 --no-pager
```

```bash
systemctl status unbound --no-pager
```

```bash
/usr/libexec/unbound-helper root_trust_anchor_update

echo $?
```

```bash
systemctl mask unbound-resolvconf.service
```

```bash
systemctl reset-failed
```

```bash
ls -l /etc/resolv.conf
```

```bash
dig @127.0.0.1 -p 5335 openai.com
```

```bash
dig @192.168.1.20 -p 5335 openai.com
```

```bash
dig @127.0.0.1 -p 5335 dnssec-failed.org
```

```bash
ss -lnptu | grep 5335
```

```bash
unbound-control stats_noreset
```
---

```
systemctl mask unbound-resolvconf.service
systemctl reset-failed
nano /etc/netplan/*.yaml
```

```
# Added by Armbian
#
# Reference: https://netplan.readthedocs.io/en/stable/netplan-yaml/
#
# Let systemd-networkd manage all Ethernet devices on this system, but be configured by Netplan.

network:
  version: 2
  renderer: networkd

  ethernets:
    all-eth-interfaces:
      match:
        name: "e*"
      dhcp4: yes
      dhcp6: yes
      dhcp4-overrides:
        use-dns: false
      dhcp6-overrides:
        use-dns: false
      ipv6-privacy: yes

    all-lan-interfaces:
      match:
        name: "lan[0-9]*"
      dhcp4: yes
      dhcp6: yes
      dhcp4-overrides:
        use-dns: false
      dhcp6-overrides:
        use-dns: false
      ipv6-privacy: yes

    all-wan-interfaces:
      match:
        name: "wan[0-9]*"
      dhcp4: yes
      dhcp6: yes
      dhcp4-overrides:
        use-dns: false
      dhcp6-overrides:
        use-dns: false
      ipv6-privacy: yes
```

```
netplan generate
```

```
netplan apply
```
