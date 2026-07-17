
---

# Criar diretórios

```bash
mkdir -p /opt/docker/pihole
mkdir -p /opt/docker/pihole/etc-pihole
mkdir -p /opt/docker/pihole/etc-dnsmasq.d
```

---

# Criar docker-compose.yml

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

---

# Validar compose

```bash
cat /opt/docker/pihole/docker-compose.yml
```

---

# Garantir que o Unbound está funcionando

Antes de instalar o Pi-hole, confirme que o Unbound responde consultas.

```bash
dig @127.0.0.1 -p 5335 openai.com
```

O retorno deve conter:

```text
status: NOERROR
```

---

# Configurar o systemd-resolved

```bash
nano /etc/systemd/resolved.conf
```

Conteúdo:

```ini
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
```

Validar:

```bash
cat /etc/systemd/resolved.conf
```

Aplicar:

```bash
systemctl restart systemd-resolved
```

Confirmar:

```bash
cat /etc/resolv.conf
```

Deve conter:

```text
nameserver 127.0.0.1
```

---

# Subir o Pi-hole

```bash
cd /opt/docker/pihole
```

```bash
docker compose pull
```

```bash
docker compose up -d
```

---

# Validação inicial

```bash
docker ps
```

```bash
docker logs --tail=100 pihole
```

```bash
ss -lnptu | grep -E ':53|:80|:5335'
```

---

# Validar DNS

```bash
dig @127.0.0.1 openai.com
```

```bash
dig @192.168.1.99 openai.com
```

---

# Validar cache do Unbound

```bash
unbound-control stats_noreset | grep cache
```

---

# Validar Gravity

```bash
docker exec pihole ls -lh /etc/pihole/gravity.db
```

O arquivo deve existir.

---

# Caso o container permaneça unhealthy

Em algumas instalações o Pi-hole inicia antes de conseguir utilizar o Unbound como resolvedor upstream. Nessa situação a Gravity não é criada automaticamente.

Execute:

```bash
docker exec pihole pihole -g
```

Após concluir:

```bash
docker restart pihole
```

Aguarde cerca de 60 segundos.

---

# Validação final

```bash
docker ps
```

O container deve estar:

```text
healthy
```

Verificar o status do Pi-hole:

```bash
docker exec pihole pihole status
```

Testar resolução DNS:

```bash
dig @127.0.0.1 openai.com
```

```bash
dig @192.168.1.99 openai.com
```

Confirmar o upstream configurado:

```bash
docker exec pihole pihole-FTL --config dns.upstreams
```

Resultado esperado:

```text
[ 127.0.0.1#5335 ]
```

---

# Interface Web

Acesse:

```
http://192.168.1.99/admin
```

Senha:

A definida na variável:

```yaml
FTLCONF_webserver_api_password
```

---
