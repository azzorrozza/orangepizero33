
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

Autenticar o dispositivo:

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
sysctl net.ipv4.ip_forward
```

```bash
sysctl net.ipv6.conf.all.forwarding
```

```bash
apt install -y networkd-dispatcher jq
```

```bash
nano /etc/networkd-dispatcher/routable.d/50-tailscale-route
```

```bash
#!/bin/bash
set -euo pipefail

LOGGER_TAG="tailscale-subnet-router"

# Run only for the primary Ethernet interface
[ "$IFACE" != "end0" ] && exit 0

# Wait until tailscaled is active (up to 30 seconds)
for i in {1..30}; do
    systemctl is-active --quiet tailscaled && break
    sleep 1
done

systemctl is-active --quiet tailscaled || exit 0

# Detect the IPv4 subnet assigned to the interface
ROUTE=$(ip -4 route show dev "$IFACE" proto kernel | awk '{print $1}')

[ -z "$ROUTE" ] && exit 0

logger -t "$LOGGER_TAG" "Detected subnet: $ROUTE"

# Currently advertised Tailscale routes
CURRENT=$(tailscale debug prefs | jq -r '.AdvertiseRoutes // [] | .[]' 2>/dev/null)

# Skip if the subnet is already being advertised
if printf '%s\n' "$CURRENT" | grep -qxF "$ROUTE"; then
    logger -t "$LOGGER_TAG" "Route $ROUTE is already advertised."
    exit 0
fi

logger -t "$LOGGER_TAG" "Updating advertised route to $ROUTE"

tailscale set \
    --advertise-routes="$ROUTE" \
    --advertise-exit-node \
    --accept-routes
```

```bash
cat /etc/networkd-dispatcher/routable.d/50-tailscale-route
```

```bash
chmod +x /etc/networkd-dispatcher/routable.d/50-tailscale-route
```

```bash
bash -n /etc/networkd-dispatcher/routable.d/50-tailscale-route
```

```bash
systemctl restart networkd-dispatcher
```

```bash
systemctl status networkd-dispatcher --no-pager
```

```bash
networkctl reconfigure end0
```

```bash
journalctl -t tailscale-subnet-router -n 20 --no-pager
```

```bash
tailscale debug prefs | grep -A5 AdvertiseRoutes
```

```bash
ethtool -K end0 rx-udp-gro-forwarding on
```

```bash
ethtool -k end0 | grep udp
```

```bash
nano /etc/systemd/system/ethtool-end0.service
```

```ini
[Unit]
Description=Enable UDP GRO forwarding on end0
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -K end0 rx-udp-gro-forwarding on
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

```bash
cat /etc/systemd/system/ethtool-end0.service
```

```bash
systemctl daemon-reload
```

```bash
systemctl enable ethtool-end0.service
```

```bash
systemctl start ethtool-end0.service
```

```bash
systemctl status ethtool-end0.service --no-pager
```

```bash
ethtool -k end0 | grep udp
```

```bash
systemctl status tailscaled --no-pager
```

```bash
systemctl is-enabled tailscaled
```

```bash
systemctl is-enabled networkd-dispatcher
```

```bash
systemctl is-enabled ethtool-end0.service
```

Acesse o **Admin Console** do Tailscale e aprove:

- **Exit Node**
- **Subnet Route**

Após a aprovação, execute:

```bash
tailscale status
```

```bash
tailscale debug prefs | grep -A5 AdvertiseRoutes
```

```bash
tailscale netcheck
```

---
