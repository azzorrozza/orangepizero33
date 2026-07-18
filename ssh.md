
---

# 1. Gerar a chave SSH do root

No Windows, abra o **PowerShell**.

```powershell
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_root -C "root"
```

Confirmar que a chave foi criada:

```powershell
dir ~/.ssh
```

---

# 2. Instalar a chave do root

Copiar a chave pública:

```powershell
Get-Content ~/.ssh/id_ed25519_root.pub | Set-Clipboard
```

Conectar utilizando senha (configuração padrão do Armbian):

```powershell
ssh root@192.168.1.99
```

Criar o diretório:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Adicionar a chave:

```bash
cat >> ~/.ssh/authorized_keys
```

Cole toda a chave pública.

Pressione:

```
ENTER
```

Depois:

```
CTRL+D
```

Corrigir permissões:

```bash
chmod 600 ~/.ssh/authorized_keys
```

Confirmar:

```bash
cat ~/.ssh/authorized_keys
```

---

# 3. Testar o login do root por chave

No Windows:

```powershell
ssh -i ~/.ssh/id_ed25519_root root@192.168.1.99
```

Se entrar normalmente, a chave do root está funcionando.

Saia da sessão:

```bash
exit
```

---

# 4. Gerar a chave SSH do usuário azzor

No Windows:

```powershell
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_azzor -C "azzor"
```

Confirmar:

```powershell
dir ~/.ssh
```

---

# 5. Instalar a chave do usuário azzor

Copiar a chave pública:

```powershell
Get-Content ~/.ssh/id_ed25519_azzor.pub | Set-Clipboard
```

Entrar utilizando senha:

```powershell
ssh azzor@192.168.1.99
```

Criar o diretório:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Adicionar a chave:

```bash
cat >> ~/.ssh/authorized_keys
```

Cole toda a chave pública.

Pressione:

```
ENTER
```

Depois:

```
CTRL+D
```

Corrigir permissões:

```bash
chmod 600 ~/.ssh/authorized_keys
```

Confirmar:

```bash
cat ~/.ssh/authorized_keys
```

---

# 6. Testar o login do usuário azzor

No Windows:

```powershell
ssh -i ~/.ssh/id_ed25519_azzor azzor@192.168.1.99
```

Se entrar normalmente, a chave está funcionando.

Saia da sessão:

```bash
exit
```

---

# 7. Configurar o OpenSSH

**Somente depois que os dois testes acima funcionarem.**

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

PermitRootLogin prohibit-password
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

Verificar:

```bash
cat /etc/ssh/sshd_config
```

Validar:

```bash
sshd -t
```

Se nenhum erro for exibido:

```bash
systemctl restart ssh
```

---

# 8. Validar o serviço

```bash
systemctl status ssh --no-pager
```

---

# 9. Confirmar a porta SSH

```bash
ss -tlnp | grep :22
```

---

# 10. Confirmar a versão

```bash
ssh -V
```

---

# 11. Testar login do root

No Windows:

```powershell
ssh -v -i ~/.ssh/id_ed25519_root root@192.168.1.99
```

Resultado esperado:

```text
Offering public key
Server accepts key
Authenticated using "publickey"
```

---

# 12. Testar login do usuário azzor

No Windows:

```powershell
ssh -v -i ~/.ssh/id_ed25519_azzor azzor@192.168.1.99
```

Resultado esperado:

```text
Offering public key
Server accepts key
Authenticated using "publickey"
```

---

# 13. Validar a configuração

```bash
sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowagentforwarding|allowtcpforwarding|disableforwarding|x11forwarding'
```

Resultado esperado:

```text
permitrootlogin without-password
pubkeyauthentication yes
passwordauthentication no
x11forwarding no
allowtcpforwarding no
allowagentforwarding no
disableforwarding yes
```

---

# 14. Conferir permissões do root

```bash
ls -ld /root/.ssh
ls -l /root/.ssh/authorized_keys
```

Resultado esperado:

```text
drwx------ /root/.ssh
-rw------- authorized_keys
```

---

# 15. Conferir permissões do usuário azzor

```bash
ls -ld /home/azzor/.ssh
ls -l /home/azzor/.ssh/authorized_keys
```

Resultado esperado:

```text
drwx------ /home/azzor/.ssh
-rw------- authorized_keys
```

---

## Conexões futuras

### Root

```powershell
ssh -i ~/.ssh/id_ed25519_root root@192.168.1.99
```

### Usuário azzor

```powershell
ssh -i ~/.ssh/id_ed25519_azzor azzor@192.168.1.99
```

---

# 16. Configurar o cliente SSH (Windows)

Criar o arquivo:

```text
C:\Users\azzor\.ssh\config
```

Adicionar:

```sshconfig
Host orangepi
    HostName 192.168.1.99
    User azzor
    IdentityFile ~/.ssh/id_ed25519_azzor
    IdentitiesOnly yes

Host orangepi-root
    HostName 192.168.1.99
    User root
    IdentityFile ~/.ssh/id_ed25519_root
    IdentitiesOnly yes
```

Salvar o arquivo.

---

# 17. Testar os atalhos

### Usuário azzor

```powershell
ssh orangepi
```

Resultado esperado:

```text
Authenticated using "publickey"
```

---

### Root

```powershell
ssh orangepi-root
```

Resultado esperado:

```text
Authenticated using "publickey"
```

---

# 18. Conexões futuras

Enquanto o acesso ao **root** estiver permitido:

### Usuário azzor

```powershell
ssh orangepi
```

### Root

```powershell
ssh orangepi-root
```

---

## Após desabilitar o login do root

Quando alterar no `/etc/ssh/sshd_config`:

```text
PermitRootLogin no
```

Reinicie o serviço:

```bash
systemctl restart ssh
```

A partir desse momento o acesso administrativo deverá ser feito pelo usuário **azzor**:

```powershell
ssh orangepi
```

Caso seja necessário executar comandos administrativos:

```bash
sudo -i
```

O atalho `orangepi-root` deixará de funcionar e poderá ser removido do arquivo:

```text
C:\Users\azzor\.ssh\config
```

---
