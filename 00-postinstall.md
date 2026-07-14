# OrangePi Zero 3 - Pós-instalação

Após concluir a instalação do Armbian, é recomendado atualizar completamente o sistema antes de instalar qualquer serviço.

Esta etapa garante que todos os pacotes estejam nas versões mais recentes, incluindo correções de segurança, kernel e firmware.

---

# 1. Atualizar a lista de pacotes

```bash
apt update
```

---

# 2. Atualizar os pacotes instalados

```bash
apt upgrade -y
```

---

# 3. Atualizar componentes do Armbian

```bash
armbian-upgrade
```

Durante a execução poderão ser instaladas versões mais recentes do kernel, bootloader e firmware.

---

# 4. Reiniciar o sistema

```bash
reboot
```

Após o reboot, reconecte ao equipamento via SSH para continuar a configuração.

---

# Verificações

Verificar a versão do sistema:

```bash
cat /etc/os-release
```

Verificar a versão do kernel:

```bash
uname -a
```

Verificar se existem atualizações pendentes:

```bash
apt update
apt list --upgradable
```

---

# Estado esperado

- ✔ Sistema atualizado
- ✔ Kernel atualizado (quando disponível)
- ✔ Firmware atualizado (quando disponível)
- ✔ Equipamento reiniciado
- ✔ Pronto para a instalação dos demais serviços
