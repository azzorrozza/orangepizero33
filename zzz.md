
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

```bash
#!/bin/bash
set -euo pipefail

LOGGER_TAG="tailscale-subnet-router"

# Executa apenas para a interface Ethernet principal
[ "$IFACE" != "end0" ] && exit 0

# Aguarda o tailscaled ficar ativo (máximo 30 segundos)
for i in {1..30}; do
    systemctl is-active --quiet tailscaled && break
    sleep 1
done

systemctl is-active --quiet tailscaled || exit 0

# Descobre automaticamente a subnet IPv4 da interface
ROUTE=$(ip -4 route show dev "$IFACE" proto kernel | awk '{print $1}')

[ -z "$ROUTE" ] && exit 0

logger -t "$LOGGER_TAG" "Subnet detectada: $ROUTE"

# Rotas atualmente anunciadas pelo Tailscale
CURRENT=$(tailscale debug prefs | jq -r '.AdvertiseRoutes // [] | .[]' 2>/dev/null)

# Se a subnet já estiver anunciada, não altera a configuração
if printf '%s\n' "$CURRENT" | grep -qxF "$ROUTE"; then
    logger -t "$LOGGER_TAG" "Rota $ROUTE já anunciada."
    exit 0
fi

logger -t "$LOGGER_TAG" "Atualizando rota anunciada para $ROUTE"

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
systemctl restart networkd-dispatcher
```

```bash
networkctl reconfigure end0
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



---
