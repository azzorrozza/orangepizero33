# OrangePi Zero 3 - Home Server

Guia completo para configuração de uma **OrangePi Zero 3** utilizando **Armbian**, com foco na criação de um servidor doméstico moderno, seguro e totalmente baseado em software livre.

O objetivo deste projeto é documentar todas as etapas necessárias para transformar a OrangePi em um servidor para uso 24/7, oferecendo serviços de rede, acesso remoto, DNS recursivo, containers e gerenciamento centralizado.

Toda a documentação foi escrita na ordem em que as configurações devem ser realizadas, permitindo reproduzir a instalação do zero.

---

# Objetivos

Ao final de todos os guias, a OrangePi Zero 3 estará preparada para:

- atuar como servidor doméstico de baixo consumo;
- fornecer acesso remoto seguro através do Tailscale;
- funcionar como servidor DNS recursivo com cache e DNSSEC;
- hospedar aplicações utilizando Docker;
- gerenciar containers através do Portainer;
- oferecer bloqueio de anúncios e rastreadores utilizando Pi-hole;
- manter todas as configurações persistentes após reinicializações.

---

# Requisitos

- OrangePi Zero 3
- Armbian (Debian Trixie)
- Acesso SSH
- Conexão com a Internet

---

# Documentação

Os guias devem ser executados na seguinte ordem:

| Etapa | Documento | Descrição |
|-------:|-----------|-----------|
| 1 | **00-postinstall.md** | Atualização inicial do sistema após a instalação do Armbian. |
| 2 | **01-tailscale.md** | Configuração do Tailscale como Exit Node e Subnet Router. |
| 3 | **02-unbound.md** | Configuração do Unbound como servidor DNS recursivo com cache e DNSSEC. |

---

# Próximos guias

Os próximos documentos previstos para este repositório são:

- Docker
- Portainer
- Pi-hole

---

# Estrutura do repositório

```text
.
├── README.md
├── 00-postinstall.md
├── 01-tailscale.md
├── 02-unbound.md
├── 03-docker.md          (em desenvolvimento)
├── 04-portainer.md       (em desenvolvimento)
└── 05-pihole.md          (em desenvolvimento)
```

---

# Estado atual

- ✔ Estrutura inicial do projeto criada
- ✔ Pós-instalação do Armbian documentada
- ✔ Tailscale documentado
- ✔ Unbound documentado
- 🚧 Docker (em desenvolvimento)
- 🚧 Portainer (em desenvolvimento)
- 🚧 Pi-hole (em desenvolvimento)

---

# Licença

Este projeto é disponibilizado para fins de estudo e compartilhamento de conhecimento. Sinta-se à vontade para utilizá-lo, adaptá-lo e contribuir com melhorias.
