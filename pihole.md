# Arquitetura Final do Projeto

Após diversos testes durante a implantação da OrangePi Zero 3, esta passou a ser a arquitetura recomendada para o projeto.

```
                    Internet
                        │
                        ▼
                 Root DNS Servers
                        │
                        ▼
                Unbound (Host Linux)
                  127.0.0.1:5335
                        │
                        ▼
         Pi-hole (Docker - network_mode: host)
                  127.0.0.1:53
                        │
        ┌───────────────┴───────────────┐
        ▼                               ▼
     LAN Clients                 Tailscale Clients
```

## Por que esta arquitetura?

Durante a implementação foram avaliadas duas possibilidades:

### Opção 1 — Docker Bridge

```
Clientes
    │
    ▼
Pi-hole (Docker Bridge)
    │
    ▼
172.18.0.1:5335
    │
    ▼
Unbound
```

Embora funcional, essa abordagem apresentou alguns inconvenientes:

- necessidade de publicar a porta 53 utilizando `docker-proxy`;
- o host não conseguia consultar corretamente o próprio Pi-hole em `127.0.0.1:53`;
- durante a instalação do Pi-hole o Docker ficou sem resolução DNS para baixar imagens;
- dependência do endereço da bridge Docker (`172.18.0.1`);
- maior complexidade na documentação e na manutenção.

---

### Opção 2 — Host Network (Recomendada)

```
Clientes
    │
    ▼
Pi-hole (network_mode: host)
    │
    ▼
127.0.0.1:5335
    │
    ▼
Unbound
```

Esta arquitetura elimina completamente os problemas encontrados durante os testes.

## Vantagens

- Não utiliza `docker-proxy` para DNS.
- O Pi-hole escuta diretamente na porta 53 do host.
- O Unbound permanece isolado na porta 5335.
- O próprio sistema operacional pode utilizar o Pi-hole normalmente.
- Não depende do gateway da bridge Docker (`172.18.0.1`).
- Menor quantidade de NAT e redirecionamentos.
- Configuração mais simples.
- Mais fácil de manter.
- Menor possibilidade de loops de DNS.
- Fluxo de resolução mais previsível.

## Fluxo de resolução

### Sistema Operacional

```
Aplicação
    │
    ▼
systemd-resolved
    │
    ▼
127.0.0.1:53
    │
    ▼
Pi-hole
    │
    ▼
127.0.0.1:5335
    │
    ▼
Unbound
    │
    ▼
Root DNS
```

### Clientes da rede

```
Cliente
    │
    ▼
Pi-hole
    │
    ▼
Unbound
    │
    ▼
Root DNS
```

## Ordem recomendada dos guias

1. 00 - Post Install
2. 01 - Tailscale
3. 02 - Docker
4. 03 - Unbound (porta 5335)
5. 04 - Pi-hole (network_mode: host)

Dessa forma o Unbound já nasce preparado para atender o Pi-hole, evitando qualquer alteração posterior na configuração.

## Configuração adotada

### Unbound

- Executa diretamente no host.
- Porta **5335**.
- DNSSEC habilitado.
- Cache habilitado.
- Servidor recursivo completo.

### Pi-hole

- Executa em Docker.
- `network_mode: host`
- Porta **53** do host.
- Upstream DNS:

```
127.0.0.1#5335
```

### systemd-resolved

Permanece ativo apenas como resolvedor local do sistema.

```
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
```

## Resultado final

Todo o ambiente passa a utilizar exatamente o mesmo fluxo de resolução:

- Sistema operacional
- Docker
- Pi-hole
- Clientes da LAN
- Clientes via Tailscale

Todos resolvem nomes através do Pi-hole, que utiliza o Unbound como resolvedor recursivo local, sem depender de servidores DNS públicos como Cloudflare, Google ou Quad9.
