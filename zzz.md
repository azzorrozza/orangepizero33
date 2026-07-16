
---

```bash
apt update && apt upgrade -y && armbian-upgrade
```

```bash
reboot
```

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

```bash
tailscale up
```

```bash
nano /etc/sysctl.d/99-tailscale.conf
```

```conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

```bash
sysctl -p /etc/sysctl.d/99-tailscale.conf
```

```bash
apt install -y networkd-dispatcher jq
```

```bash
nano /etc/networkd-dispatcher/routable.d/50-tailscale-route
```
---
