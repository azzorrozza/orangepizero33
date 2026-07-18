# OrangePi Zero 3 - Configuração Segura do SSH com Chave ED25519

Este guia configura o acesso remoto via **SSH utilizando autenticação por chave pública (ED25519)**, eliminando a autenticação por senha e aplicando uma configuração de segurança recomendada para servidores.

Ao final deste guia será possível:

- gerar um par de chaves SSH utilizando o OpenSSH;
- armazenar as chaves no diretório padrão do sistema;
- instalar a chave pública na OrangePi;
- acessar o servidor utilizando apenas a chave privada;
- aplicar uma configuração endurecida do OpenSSH;
- desabilitar autenticação por senha;
- documentar um procedimento de recuperação de acesso.

---

# 1. Gerar uma chave SSH

No Windows, abra o **PowerShell**.

Execute:

```powershell
ssh-keygen -t ed25519 -C "azzor"
```

Quando for solicitado:

```text
Enter file in which to save the key
```

Pressione apenas:

```text
ENTER
```

Será utilizado o diretório padrão do OpenSSH:

```text
C:\Users\<usuario>\.ssh\
```

Os arquivos criados serão:

```text
C:\Users\<usuario>\.ssh\
├── id_ed25519
└── id_ed25519.pub
```

Onde:

- `id_ed25519` → chave privada (**NUNCA compartilhe**)
- `id_ed25519.pub` → chave pública

Verifique:

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

Copie a chave pública para a área de transferência:

```powershell
Get-Content ~/.ssh/id_ed25519.pub | Set-Clipboard
```

Conecte-se normalmente utilizando senha:

```powershell
ssh root@192.168.1.20
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

Exemplo:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3rMpLejpN7NPPhPbdnZOz1yg03qa8Ex35h6PCcc8yo azzor
```

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

# 3. Testar a autenticação por chave

Abra um novo PowerShell.

Execute:

```powershell
ssh root@192.168.1.20
```

Caso tenha definido uma passphrase, ela será solicitada.

O login deverá ocorrer sem solicitar a senha do usuário root.

---

# 4. Configurar o OpenSSH

Somente após confirmar que o login por chave funciona.

Editar:

```bash
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

Verificar a configuração:

```bash
sshd -t
```

Se nenhum erro for exibido, reiniciar o serviço:

```bash
systemctl restart ssh
```

---

# 5. Testar antes de fechar a sessão atual

**Muito importante**

Não feche a sessão SSH atual.

Abra outro PowerShell.

Execute:

```powershell
ssh root@192.168.1.20
```

Se o login ocorrer normalmente utilizando apenas a chave SSH, a configuração foi aplicada corretamente.

Somente então feche a sessão antiga.

---

# 6. (Opcional) Desabilitar completamente o login do root

Quando existir um usuário administrativo com permissões de sudo, recomenda-se impedir qualquer login direto do root.

Editar:

```bash
nano /etc/ssh/sshd_config
```

Alterar:

```text
PermitRootLogin prohibit-password
```

para:

```text
PermitRootLogin no
```

Salvar.

Validar:

```bash
sshd -t
```

Reiniciar:

```bash
systemctl restart ssh
```

---

# Recuperação de acesso

Caso a chave seja perdida e ainda exista acesso físico (console, teclado ou serial), editar:

```bash
nano /etc/ssh/sshd_config
```

Alterar temporariamente:

```text
PermitRootLogin yes
PasswordAuthentication yes
KbdInteractiveAuthentication yes
```

Salvar.

Validar:

```bash
sshd -t
```

Reiniciar:

```bash
systemctl restart ssh
```

Após recuperar o acesso:

- gerar uma nova chave;
- instalar a nova chave pública;
- confirmar o funcionamento;
- restaurar a configuração segura do SSH.

---

# Testes

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
ssh -v root@192.168.1.20
```

Resultado esperado:

```text
Offering public key
Authentication succeeded (publickey)
```

---

## Validar a configuração

```bash
sshd -T | grep -E "permitrootlogin|passwordauthentication|pubkeyauthentication|x11forwarding|allowtcpforwarding|disableforwarding"
```

Resultado esperado:

```text
permitrootlogin prohibit-password
passwordauthentication no
pubkeyauthentication yes
x11forwarding no
allowtcpforwarding no
disableforwarding yes
```

---

## Conferir permissões

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

- ✔ Chave SSH ED25519 criada
- ✔ Chave armazenada no diretório padrão do OpenSSH
- ✔ Chave pública instalada na OrangePi
- ✔ Login utilizando apenas chave SSH
- ✔ Autenticação por senha desabilitada
- ✔ Login do root permitido apenas por chave
- ✔ X11 desabilitado
- ✔ Forwarding desabilitado
- ✔ Configuração endurecida do OpenSSH aplicada
- ✔ Procedimento de recuperação documentado
