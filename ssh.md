# OrangePi Zero 3 - SSH com autenticação por chave

Este guia configura o OpenSSH para permitir acesso **exclusivamente por chave pública**, desabilitando completamente a autenticação por senha.

Ao final:

- ✔ Login do **root** apenas por chave SSH
- ✔ Login do usuário **azzor** apenas por chave SSH
- ✔ Autenticação por senha desabilitada
- ✔ Chave protegida por passphrase

---

# 1. Gerar uma chave SSH

No Windows, abra o **PowerShell**.

Execute:

```powershell
ssh-keygen -t ed25519 -C "azzor"
```

Aceite o caminho padrão pressionando **ENTER**.

Caso solicitado, informe uma **passphrase**.

Verifique se a chave foi criada:

```powershell
dir ~/.ssh
```

Resultado esperado:

```text
id_ed25519
id_ed25519.pub
```

---

# 2. Instalar a chave para o usuário root

Copie a chave pública:

```powershell
Get-Content ~/.ssh/id_ed25519.pub | Set-Clipboard
```

Conecte-se utilizando senha:

```powershell
ssh root@192.168.1.99
```

Criar o diretório SSH:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Adicionar a chave pública:

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

# 3. Instalar a mesma chave para o usuário azzor

Ainda conectado como **root**, execute:

```bash
mkdir -p /home/azzor/.ssh
chmod 700 /home/azzor/.ssh
```

Adicionar a chave:

```bash
cat >> /home/azzor/.ssh/authorized_keys
```

Cole exatamente a mesma chave pública.

Pressione:

```
ENTER
```

Depois:

```
CTRL+D
```

Corrigir proprietário:

```bash
chown -R azzor:azzor /home/azzor/.ssh
```

Corrigir permissões:

```bash
chmod 600 /home/azzor/.ssh/authorized_keys
```

Confirmar:

```bash
cat /home/azzor/.ssh/authorized_keys
```

---

# 4. Confirmar que ambas as contas funcionam

No Windows, teste o root:

```powershell
ssh root@192.168.1.99
```

Depois teste o usuário comum:

```powershell
ssh azzor@192.168.1.99
```

Ambos deverão solicitar apenas a **passphrase da chave**.

Somente continue quando os dois logins estiverem funcionando.

---

# 5. Configurar o OpenSSH

Editar:

```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
nano /etc/ssh/sshd_config
```

Substitua todo o conteúdo por:

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

# 6. Testar novamente

Sem fechar a sessão atual, abra um novo PowerShell.

Testar o root:

```powershell
ssh root@192.168.1.99
```

Testar o usuário comum:

```powershell
ssh azzor@192.168.1.99
```

Os dois logins deverão:

- solicitar apenas a passphrase da chave;
- não solicitar senha do usuário;
- realizar o login normalmente.

Somente depois feche a sessão antiga.

---

# Verificar o serviço

```bash
systemctl status ssh --no-pager
```

---

# Confirmar que a porta está aberta

```bash
ss -tlnp | grep :22
```

---

# Verificar a versão

```bash
ssh -V
```

---

# Confirmar autenticação por chave

Testar o root:

```powershell
ssh -v root@192.168.1.99
```

Testar o usuário comum:

```powershell
ssh -v azzor@192.168.1.99
```

Resultado esperado para ambos:

```text
Offering public key
Server accepts key
Authenticated using "publickey"
```

---

# Validar a configuração

```bash
sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowagentforwarding|allowtcpforwarding|disableforwarding|x11forwarding'
```

Resultado esperado:

```text
permitrootlogin prohibit-password
pubkeyauthentication yes
passwordauthentication no
allowagentforwarding no
allowtcpforwarding no
disableforwarding yes
x11forwarding no
```

---

# Conferir permissões

Root:

```bash
ls -ld /root/.ssh
ls -l /root/.ssh/authorized_keys
```

Usuário comum:

```bash
ls -ld /home/azzor/.ssh
ls -l /home/azzor/.ssh/authorized_keys
```

Resultado esperado:

```text
drwx------ .ssh
-rw------- authorized_keys
```

---

# Estado final

- ✔ Chave ED25519 criada
- ✔ Chave armazenada em `~/.ssh`
- ✔ Chave instalada para o usuário **root**
- ✔ Chave instalada para o usuário **azzor**
- ✔ Root autenticando apenas por chave
- ✔ Usuário autenticando apenas por chave
- ✔ Autenticação por senha desabilitada
- ✔ Chave protegida por passphrase
- ✔ OpenSSH configurado com hardening básico
