
#Instalar o MySpeed

O MySpeed é uma aplicação para monitoramento contínuo da velocidade da Internet, permitindo executar testes, armazenar histórico e visualizar gráficos através da interface web.

Criar o diretório da aplicação:

```bash
mkdir -p /opt/docker/myspeed/data
```

Criar o arquivo:

```bash
nano /opt/docker/myspeed/docker-compose.yml
```

Conteúdo:

```yaml
services:
  myspeed:
    image: germannewsmaker/myspeed:latest
    container_name: myspeed
    restart: unless-stopped

    ports:
      - "5216:5216"

    volumes:
      - ./data:/myspeed/data

    networks:
      - services

networks:
  services:
    external: true
```

Iniciar a aplicação:

```bash
cd /opt/docker/myspeed

docker compose pull
docker compose up -d
```

Verificar se o container iniciou corretamente:

```bash
docker ps
```

Visualizar os logs:

```bash
docker logs myspeed
```

Acessar a interface web:

```text
http://IP_DO_SERVIDOR:5216
```

Todos os dados da aplicação ficarão armazenados em:

```text
/opt/docker/myspeed/data
```

---

## Verificar o MySpeed

Container:

```bash
docker ps
```

Logs:

```bash
docker logs myspeed
```

Compose:

```bash
docker compose ls
```

Inspeção:

```bash
docker inspect myspeed
```

---
