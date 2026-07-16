
---

```bash
mkdir -p /opt/docker/pihole
```

```bash
mkdir -p /opt/docker/pihole/etc-pihole
```

```bash
mkdir -p /opt/docker/pihole/etc-dnsmasq.d
```

```bash
nano /opt/docker/pihole/docker-compose.yml
```

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole

    hostname: orangepi

    network_mode: host

    restart: unless-stopped

    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d

    environment:
      TZ: America/Sao_Paulo

      FTLCONF_dns_upstreams: "127.0.0.1#5335"

      FTLCONF_dns_listeningMode: "all"

      FTLCONF_webserver_port: "80"

      FTLCONF_webserver_api_password: "090611"
```

```bash
cat /opt/docker/pihole/docker-compose.yml
```

```bash
cd /opt/docker/pihole
```

```bash
docker compose pull
```

```bash
docker compose up -d
```

```bash
docker ps
```

```bash
docker logs -f pihole
```

```bash
ss -lnptu | grep -E ':53|:80|:5335'
```

```bash
dig @127.0.0.1 openai.com
```

```bash
dig @192.168.1.10 openai.com
```

```bash
unbound-control stats_noreset | grep cache
```

```bash
nano /etc/systemd/resolved.conf
```

```bash
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
```

```bash
cat /etc/systemd/resolved.conf
```

```bash
systemctl restart systemd-resolved
```
