
---

# 1. Gerar uma chave SSH

No Windows, abra o **PowerShell**.

Execute:

```powershell
ssh-keygen -t ed25519 -C "azzor"
```

```powershell
dir ~/.ssh
```

---

# 2. Instalar a chave na OrangePi

Copie a chave pública para a área de transferência:

```powershell
Get-Content ~/.ssh/id_ed25519.pub | Set-Clipboard
```

Conecte-se normalmente utilizando senha:

```powershell
ssh root@192.168.1.99
```

Criar o diretório do SSH:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Adicionar a chave pública:

```bash
cat >> ~/.ssh/authorized_keys
```

Cole a chave pública completa.

Pressione:

```
ENTER
```

Depois:

```
CTRL+D
```

Corrigir as permissões:

```bash
chmod 600 ~/.ssh/authorized_keys
```

Confirmar:

```bash
cat ~/.ssh/authorized_keys
```

---

# 4. Configurar o OpenSSH

Somente após confirmar que o login por chave funciona.

Editar:

```bash
rm /etc/ssh/sshd_config
nano /etc/ssh/sshd_config
```

Utilize a seguinte configuração:

```text
Include /etc/ssh/sshd_config.d/*.conf

Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no

UsePAM yes

LoginGraceTime 30
MaxAuthTries 3
MaxSessions 5
StrictModes yes

AllowAgentForwarding no
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no
DisableForwarding yes

X11Forwarding no

PermitTTY yes
PermitUserEnvironment no
PrintMotd no
PrintLastLog yes

TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 2

Compression no

SyslogFacility AUTH
LogLevel VERBOSE

AcceptEnv LANG LC_* COLORTERM NO_COLOR

Subsystem sftp /usr/lib/openssh/sftp-server
```

Salvar o arquivo.

Verificar a configuração:

```bash
sshd -t
```

Se nenhum erro for exibido, reiniciar o serviço:

```bash
systemctl restart ssh
```

---

## Verificar o serviço

```bash
systemctl status ssh --no-pager
```

---

## Confirmar que a porta está aberta

```bash
ss -tlnp | grep :22
```

---

## Verificar a versão

```bash
ssh -V
```

---

## Confirmar autenticação por chave

No Windows:

```powershell
ssh -v root@192.168.1.99
```

Resultado esperado:

```text
Offering public key
Authentication succeeded (publickey)
```

---

## Validar a configuração

```bash
sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowagentforwarding|allowtcpforwarding|disableforwarding|x11forwarding'
```

---

## Conferir permissões

```bash
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

---
