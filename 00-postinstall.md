
# 1. Atualizar o sistema

Antes de iniciar a configuração, atualize todos os pacotes do sistema para garantir compatibilidade com as versões mais recentes do Armbian e do Tailscale.

```bash
apt update && apt upgrade -y
armbian-upgrade
reboot
```
