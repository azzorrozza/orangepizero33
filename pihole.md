# OrangePi Zero 3 - Pi-hole + Unbound (Docker)

Este guia instala o **Pi-hole v6** em um container Docker utilizando uma rede dedicada de serviços.

O Pi-hole será responsável por:

- Bloqueio de anúncios e rastreadores
- Servidor DNS da rede
- Interface Web
- Estatísticas de consultas

Toda resolução DNS será encaminhada para o **Unbound**, instalado diretamente no host conforme o guia anterior.

Arquitetura final:

```text
                Clientes
                    │
                    ▼
             Pi-hole (Docker)
             Porta 53 (host)
                    │
                    ▼
      host.docker.internal:5335
                    │
                    ▼
        Unbound (Host - DNSSEC)
                    │
                    ▼
              Root DNS Servers
```

Esta arquitetura evita conflitos entre Docker e Unbound, mantendo ambos independentes.

---

# Pré-requisitos

Os seguintes guias devem estar concluídos:

- 00 - Pós-instalação
- 01 - Tailscale
- 02 - Unbound

O Unbound deve estar funcionando na porta:

```text
5335
```

Teste:

```bash
dig @127.0.0.1 -p 5335 openai.com
```

O resultado deve retornar normalmente.

---

# 1. Criar diretório

```bash
mkdir -p /opt/docker/pihole
cd /opt/docker/pihole
```

---

# 2. Criar a rede Docker (caso ainda não exista)

```bash
docker network create services
```

Se já existir:

```text
Error response from daemon: network with name services already exists
```

Pode ignorar.

---

# 3. Criar os diretórios persistentes

```bash
mkdir -p data/etc-pihole
mkdir -p data/etc-dnsmasq.d
```

---

# 4. Criar o docker-compose.yml

```bash
nano docker-compose.yml
```

Conteúdo:

```yaml
services:

  pihole:
    image: pihole/pihole:latest
    container_name: pihole

    hostname: pihole

    restart: unless-stopped

    networks:
      - services

    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8080:80/tcp"

    extra_hosts:
      - "host.docker.internal:host-gateway"

    environment:

      TZ: America/Sao_Paulo

      FTLCONF_webserver_api_password: SUA_SENHA

      FTLCONF_dns_listeningMode: all

      FTLCONF_dns_upstreams: host.docker.internal#5335

    volumes:
      - ./data/etc-pihole:/etc/pihole
      - ./data/etc-dnsmasq.d:/etc/dnsmasq.d

    cap_add:
      - NET_ADMIN

networks:

  services:
    external: true
```

---

# 5. Iniciar o container

```bash
docker compose pull
```

```bash
docker compose up -d
```

Verificar:

```bash
docker ps
```

Resultado esperado:

```text
STATUS: Up (healthy)
```

---

# 6. Verificar os logs

```bash
docker logs pihole --tail=50
```

Você deverá observar mensagens semelhantes a:

```text
Gravity updated

Starting pihole-FTL

Blocking status is enabled
```

---

# 7. Acessar a interface Web

```
http://IP_DA_ORANGEPI:8080/admin
```

Exemplo:

```
http://192.168.1.20:8080/admin
```

Login:

```
admin
```

Senha:

A definida em:

```yaml
FTLCONF_webserver_api_password
```

---

# 8. Confirmar o servidor upstream

No painel do Pi-hole:

```
Settings
```

↓

```
DNS
```

O upstream deverá aparecer como:

```
127.0.0.1#5335
```

ou

```
host.docker.internal#5335
```

dependendo da versão do Pi-hole.

Não é necessário alterar manualmente.

---

# 9. Verificar a porta 53

No host:

```bash
ss -lnptu | grep :53
```

Resultado esperado:

```text
tcp 0.0.0.0:53 docker-proxy

udp 0.0.0.0:53 docker-proxy
```

Enquanto o Unbound permanecerá escutando em:

```text
5335
```

---

# 10. Testar resolução DNS

No host:

```bash
dig @127.0.0.1 openai.com
```

Resultado esperado:

```text
status: NOERROR
```

Também:

```bash
dig @127.0.0.1 cloudflare.com
```

---

# 11. Confirmar o upstream

Verificar a configuração utilizada pelo Pi-hole:

```bash
docker exec pihole pihole-FTL --config dns.upstreams
```

Resultado esperado:

```text
127.0.0.1#5335
```

ou

```text
host.docker.internal#5335
```

---

# 12. Testar bloqueio

No navegador acesse:

```
https://doubleclick.net
```

A página deverá ser bloqueada.

---

# 13. Testar DNSSEC

No host:

```bash
dig @127.0.0.1 dnssec-failed.org
```

Resultado esperado:

```text
status: SERVFAIL
```

Isso confirma que:

```
Cliente
↓

Pi-hole
↓

Unbound

↓

DNSSEC
```

está funcionando corretamente.

---

# 14. Atualizar Gravity

Atualização manual:

```bash
docker exec pihole pihole updateGravity
```

---

# 15. Atualizar o Pi-hole

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

# 16. Backup

Todo o estado do Pi-hole fica em:

```text
/opt/docker/pihole/data
```

Para realizar backup basta copiar esse diretório.

---

# Estrutura final

```text
/opt/docker/pihole

├── docker-compose.yml
└── data
    ├── etc-dnsmasq.d
    └── etc-pihole
```

---

# Fluxo completo

```text
Cliente
    │
    ▼
Pi-hole (Docker)
 Porta 53
    │
    ▼
host.docker.internal:5335
    │
    ▼
Unbound
    │
    ▼
DNSSEC
    │
    ▼
Root Servers
```

---

# Comandos úteis

Ver container:

```bash
docker ps
```

Ver logs:

```bash
docker logs -f pihole
```

Reiniciar:

```bash
docker restart pihole
```

Parar:

```bash
docker stop pihole
```

Iniciar:

```bash
docker start pihole
```

Atualizar Gravity:

```bash
docker exec pihole pihole updateGravity
```

Consultar upstream:

```bash
docker exec pihole pihole-FTL --config dns.upstreams
```

Testar DNS:

```bash
dig @127.0.0.1 openai.com
```

Testar Unbound:

```bash
dig @127.0.0.1 -p 5335 openai.com
```

Ver portas:

```bash
ss -lnptu | grep :53
```

---

# Resultado esperado

Ao final deste guia teremos:

- ✅ Pi-hole executando em Docker
- ✅ Porta 53 publicada pelo container
- ✅ Unbound executando no host na porta 5335
- ✅ Resolução DNS recursiva com DNSSEC
- ✅ Cache local
- ✅ Bloqueio de anúncios
- ✅ Persistência de dados
- ✅ Atualização simples via Docker Compose
- ✅ Arquitetura desacoplada entre Docker e Unbound
