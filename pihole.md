# OrangePi Zero 3 - Pi-hole (Docker) + Unbound

Este guia instala o **Pi-hole** em Docker utilizando uma **rede Docker compartilhada** (`services`) e configurando o **Unbound** (já instalado no host) como servidor DNS upstream.

Arquitetura final:

```
Clientes
    │
    ▼
Pi-hole (Docker)
porta 53
    │
    ▼
Unbound (Host)
127.0.0.1:5335
    │
    ▼
Root DNS Servers
```

---

# 1. Criar diretório

```bash
mkdir -p /opt/docker/pihole
mkdir -p /opt/docker/pihole/etc-pihole
mkdir -p /opt/docker/pihole/etc-dnsmasq.d
```

---

# 2. Criar o docker-compose.yml

```bash
nano /opt/docker/pihole/docker-compose.yml
```

Conteúdo:

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole

    hostname: orangepi

    restart: unless-stopped

    networks:
      - services

    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"

    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d

    environment:
      TZ: America/Sao_Paulo

      FTLCONF_dns_upstreams: "host.docker.internal#5335"

      FTLCONF_dns_listeningMode: "all"

      FTLCONF_webserver_api_password: "ALTERE_A_SENHA"

    extra_hosts:
      - "host.docker.internal:host-gateway"

networks:
  services:
    external: true
```

---

# 3. Iniciar o Pi-hole

```bash
cd /opt/docker/pihole

docker compose pull

docker compose up -d
```

---

# 4. Verificar o container

```bash
docker ps
```

Resultado esperado:

```
pihole
```

---

# 5. Verificar logs

```bash
docker logs -f pihole
```

Não deverá haver erros relacionados ao DNS.

---

# 6. Confirmar acesso ao Unbound

Entrar no container:

```bash
docker exec -it pihole bash
```

Testar:

```bash
dig @host.docker.internal -p 5335 openai.com
```

Deve retornar normalmente.

Sair:

```bash
exit
```

---

# 7. Acessar a interface

```
http://IP_DA_ORANGEPI/admin
```

Exemplo:

```
http://192.168.1.10/admin
```

Entrar utilizando a senha configurada em:

```
FTLCONF_webserver_api_password
```

---

# 8. Verificações

Verificar containers:

```bash
docker ps
```

Verificar portas:

```bash
ss -lnptu | grep -E ':53|:80|:5335'
```

Resultado esperado:

- Porta **53** → Pi-hole
- Porta **80** → Pi-hole
- Porta **5335** → Unbound

---

# 9. Testes

Consultar diretamente o Pi-hole:

```bash
dig @127.0.0.1 openai.com
```

Consultar pela LAN:

```bash
dig @192.168.1.10 openai.com
```

Após algumas consultas:

```bash
unbound-control stats_noreset | grep cache
```

Os valores de `cachehits` devem começar a aumentar, indicando que o Pi-hole está encaminhando as consultas para o Unbound corretamente.
