
---

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt remove -y $pkg
done
```

```bash
apt install -y ca-certificates curl gnupg
```

```bash
install -m 0755 -d /etc/apt/keyrings
```

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg \
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

```bash
chmod a+r /etc/apt/keyrings/docker.gpg
```

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| tee /etc/apt/sources.list.d/docker.list >/dev/null
```

```bash
apt update
```

```bash
apt policy docker-ce
```

```bash
apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin
```

```bash
docker --version
```

```bash
docker compose version
```

```bash
systemctl enable docker
```

```bash
systemctl start docker
```

```bash
apt install -y tree
```

```bash
mkdir -p /opt/docker
```

```bash
tree /opt/docker
```

```bash
docker network create services
```

```bash
docker network inspect services
```

```bash
docker network ls
```

```bash
mkdir -p /opt/docker/portainer/data
```

```bash
nano /opt/docker/portainer/docker-compose.yml
```

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped

    ports:
      - "8000:8000"
      - "9443:9443"

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data

    networks:
      - services

networks:
  services:
    external: true
```

```bash
cat /opt/docker/portainer/docker-compose.yml
```

```bash
cd /opt/docker/portainer
```

```bash
docker compose up -d
```

```bash
docker ps
```

```bash
docker logs portainer
```

```bash
docker --version
```

```bash
docker compose version
```

```bash
systemctl status docker --no-pager
```

```bash
docker run hello-world
```

```bash
docker --version
docker compose version
docker info
docker ps -a
docker compose ls
docker network ls
systemctl is-enabled docker
systemctl is-active docker
```

```bash
docker ps
```

```bash
docker logs portainer
```

```bash
docker compose ls
```

```bash
docker inspect portainer
```

```bash
tree /opt/docker
```
