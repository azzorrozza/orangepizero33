# OrangePi Zero 3 - SSH com autenticação por chave

Este guia configura o OpenSSH para permitir acesso **exclusivamente por chave pública**, desabilitando completamente a autenticação por senha.

Ao final:

- ✔ Root acessa apenas por chave SSH
- ✔ Usuários comuns acessam apenas por chave SSH
- ✔ Senhas são recusadas
- ✔ Login protegido por passphrase da chave

---

# 1. Gerar uma chave SSH

No Windows, abra o **PowerShell**.

Execute:

```powershell
ssh-keygen -t ed25519 -C "azzor"
```

Aperte **ENTER** para aceitar o caminho padrão.

Caso solicitado, informe uma **passphrase**.

Verifique se os arquivos foram criados:

```powershell
dir ~/.ssh
```

Resultado esperado:

```text
id_ed25519
id_ed25519.pub
```

---

# 2. Instalar a chave na OrangePi

Copie a chave pública:

```powershell
Get-Content ~/.ssh/id_ed25519.pub | Set-Clipboard
```

Conecte-se utilizando senha (primeira configuração):

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

# 3. Confirmar que a chave funciona

Antes de alterar qualquer configuração do OpenSSH, teste o acesso.

No Windows:

```powershell
ssh root@192.168.1.99
```

Deverá solicitar apenas a **passphrase** da chave.

Abra um segundo PowerShell e teste novamente:

```powershell
ssh root@192.168.1.99
```

Somente prossiga se ambos os logins funcionarem.

---

# 4. Configurar o OpenSSH

Criar um backup:

```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
```

Editar:

```bash
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

Verificar o arquivo:

```bash
cat /etc/ssh/sshd_config
```

Validar a configuração:

```bash
sshd -t
```

Se nenhum erro for exibido:

```bash
systemctl restart ssh
```

---

# 5. Testar novamente

Sem fechar a sessão atual, abra um novo PowerShell.

Teste:

```powershell
ssh root@192.168.1.99
```

O resultado esperado é:

- solicitar apenas a passphrase da chave;
- não solicitar senha do usuário;
- login realizado com sucesso.

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

No Windows:

```powershell
ssh -v root@192.168.1.99
```

Resultado esperado:

```text
Offering public key
Server accepts key
Authenticated using "publickey"
```

---

# Validar a configuração ativa

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

```bash
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

Resultado esperado:

```text
drwx------ ~/.ssh
-rw------- authorized_keys
```

---

# Estado final

- ✔ Chave ED25519 criada
- ✔ Chave armazenada em `~/.ssh`
- ✔ Chave pública instalada na OrangePi
- ✔ Login do root permitido apenas por chave
- ✔ Login de usuários permitido apenas por chave
- ✔ Autenticação por senha desabilitada
- ✔ Passphrase protegendo a chave privada
- ✔ OpenSSH configurado com hardening básico
