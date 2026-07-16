# OrangePi Zero 3 - Pi-hole (Docker) + Unbound

Este guia instala o **Pi-hole** em Docker utilizando **`network_mode: host`** e configurando o **Unbound** (instalado no host) como servidor DNS upstream.

Como o Pi-hole utiliza a pilha de rede do próprio host, ele escuta diretamente nas portas da OrangePi, simplificando a configuração e eliminando a necessidade de mapeamento de portas ou redes Docker dedicadas.

Arquitetura final:

```
Clientes
    │
    ▼
OrangePi
    │
    ├── Pi-hole (Docker - Host Network)
    │        │
    │        ▼
    └── Unbound (Host)
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
dig @127.0.0.1 -p 5335 openai.com
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

Verificar portas utilizadas:

```bash
ss -lnptu | grep -E ':53|:80|:5335'
```

Resultado esperado:

- Porta **53** → Pi-hole
- Porta **80** → Pi-hole
- Porta **5335** → Unbound

Como o Pi-hole está utilizando `network_mode: host`, ele escuta diretamente nas portas da OrangePi.

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
nano /etc/systemd/resolved.conf
```

```bash
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
```

```bash
systemctl restart systemd-resolved
```

Os valores de `cachehits` devem começar a aumentar, indicando que o Pi-hole está encaminhando corretamente as consultas para o Unbound.

---

# Observações

- O Pi-hole utiliza a pilha de rede do host (`network_mode: host`).
- O Unbound permanece executando no host, escutando na porta **5335**.
- A porta **53** é utilizada exclusivamente pelo Pi-hole.
- A rede Docker `services` continua disponível para os demais containers (Portainer, Homepage, MySpeed, etc.), mas não é utilizada pelo Pi-hole.
