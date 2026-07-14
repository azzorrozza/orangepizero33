# OrangePi Zero 3 - Docker Platform

Este guia instala o **Docker CE** utilizando o repositório oficial da Docker, configura o ambiente para organização dos containers, cria uma rede compartilhada e instala o **Portainer CE** para administração gráfica.

Ao final da configuração, o servidor estará pronto para hospedar aplicações em containers.

---

# 1. Remover versões antigas (caso existam)

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt remove -y $pkg
done
```

---

# 2. Instalar dependências

```bash
apt update
apt install -y ca-certificates curl gnupg
```

---

# 3. Adicionar a chave GPG oficial da Docker

Criar o diretório:

```bash
install -m 0755 -d /etc/apt/keyrings
```

Baixar a chave:

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg \
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

Permitir leitura:

```bash
chmod a+r /etc/apt/keyrings/docker.gpg
```

---

# 4. Adicionar o repositório oficial

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| tee /etc/apt/sources.list.d/docker.list >/dev/null
```

Atualizar os repositórios:

```bash
apt update
```

---

# 5. Instalar o Docker

```bash
apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin
```

---

# 6. Habilitar o serviço

```bash
systemctl enable docker
systemctl start docker
```

---

# 7. Criar a estrutura de diretórios

Instalar o utilitário `tree`:

```bash
apt install -y tree
```

Criar a estrutura principal utilizada pelos containers:

```bash
mkdir -p /opt/docker
```

Verificar:

```bash
tree /opt/docker
```

> Cada aplicação criará seus próprios diretórios durante sua instalação.

---

# 8. Criar a rede Docker

Criar uma rede compartilhada entre os containers:

```bash
docker network create services
```

Verificar:

```bash
docker network ls
```

Resultado esperado:

```text
NETWORK ID     NAME       DRIVER    SCOPE
xxxxxxxxxxxx   bridge     bridge    local
xxxxxxxxxxxx   host       host      local
xxxxxxxxxxxx   none       null      local
xxxxxxxxxxxx   services   bridge    local
```

---

# 9. Instalar o Portainer CE

Criar o diretório da aplicação:

```bash
mkdir -p /opt/docker/portainer/data
```

Criar o arquivo:

```bash
nano /opt/docker/portainer/docker-compose.yml
```

Conteúdo:

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

Iniciar o Portainer:

```bash
cd /opt/docker/portainer

docker compose up -d
```

Verificar se o container iniciou:

```bash
docker ps
```

---

# 10. Obter o Setup Token (Portainer 2.39+)

Nas versões atuais do Portainer, a criação do primeiro usuário administrador utiliza um **Setup Token**.

Obter o token:

```bash
docker logs portainer
```

Será exibida uma linha semelhante a esta:

```text
no administrator account configured; admin initialization and backup restore require this setup token

setup_token=24469951a35f845507b853b2e0561b81d4c575873105b19a4ac15a6ef12e7835
```

Copie o valor informado após `setup_token=`.

> O token é utilizado apenas durante a configuração inicial do Portainer.

---

# Testes

## Docker

```bash
docker --version
```

---

## Docker Compose

```bash
docker compose version
```

---

## Serviço Docker

```bash
systemctl status docker --no-pager
```

---

## Container de teste

```bash
docker run hello-world
```

---

## Verificar o ambiente

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

---

## Verificar o Portainer

Container:

```bash
docker ps
```

Logs:

```bash
docker logs portainer
```

Compose:

```bash
docker compose ls
```

Inspeção:

```bash
docker inspect portainer
```

---

## Estrutura dos diretórios

```bash
tree /opt/docker
```

Resultado esperado:

```text
/opt/docker
├── portainer
    └── data
```

---

# Primeiro acesso ao Portainer

Após iniciar o container, acessar:

```text
https://IP_DO_SERVIDOR:9443
```

Na primeira execução será exibida a tela de criação do usuário administrador.

Informe:

* Username
* Password

Em seguida, utilize o **Setup Token** obtido anteriormente para concluir a inicialização.

Após finalizar a configuração, o token deixa de ser necessário.

---
