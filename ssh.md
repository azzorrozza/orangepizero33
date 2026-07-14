# OrangePi Zero 3 - SSH com autenticação por chave

Este guia configura o acesso remoto via **SSH utilizando autenticação por chave pública**, eliminando a necessidade de senha e aumentando significativamente a segurança do servidor.

Ao final deste guia será possível:

* gerar um par de chaves SSH no Windows;
* armazenar as chaves na pasta **Downloads**;
* instalar a chave pública na OrangePi;
* acessar o servidor utilizando apenas a chave privada;
* configurar um atalho utilizando o arquivo `config`;
* remover e substituir chaves quando necessário;
* desabilitar autenticação por senha;
* recuperar o acesso caso a chave seja perdida.

---

# 1. Gerar uma chave SSH

No Windows, abra o **PowerShell**.

Execute:

```powershell
ssh-keygen -t ed25519 -C "orangepi"
```

Quando for solicitado o local para salvar a chave, informe:

```text
C:\Users\SEU_USUARIO\Downloads\orangepi_ed25519
```

Será criado:

```text
orangepi_ed25519
orangepi_ed25519.pub
```

Onde:

* `orangepi_ed25519` → chave privada (NUNCA compartilhe)
* `orangepi_ed25519.pub` → chave pública (pode ser instalada no servidor)

---

# 2. Instalar a chave na OrangePi

Abra a chave pública:

```powershell
notepad C:\Users\SEU_USUARIO\Downloads\orangepi_ed25519.pub
```

Copie todo o conteúdo.

Conecte-se normalmente via SSH utilizando senha.

Criar o diretório caso não exista:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Editar o arquivo:

```bash
nano ~/.ssh/authorized_keys
```

Cole a chave pública em uma única linha.

Salvar.

Corrigir as permissões:

```bash
chmod 600 ~/.ssh/authorized_keys
```

---

# 3. Testar o acesso utilizando a chave

No Windows:

```powershell
ssh -i C:\Users\SEU_USUARIO\Downloads\orangepi_ed25519 root@192.168.1.20
```

Se tudo estiver correto, o login ocorrerá sem solicitar senha.

---

# 4. Criar um atalho utilizando o arquivo config

Criar o diretório (caso não exista):

```powershell
mkdir $HOME\.ssh
```

Editar:

```text
C:\Users\SEU_USUARIO\.ssh\config
```

Conteúdo:

```text
Host orangepi

    HostName 192.168.1.20

    User root

    IdentityFile C:\Users\SEU_USUARIO\Downloads\orangepi_ed25519
```

Agora basta conectar utilizando:

```powershell
ssh orangepi
```

---

# 5. Verificar as chaves autorizadas

Visualizar:

```bash
cat ~/.ssh/authorized_keys
```

Cada linha representa uma chave autorizada.

---

# 6. Adicionar uma nova chave

Editar:

```bash
nano ~/.ssh/authorized_keys
```

Adicionar a nova chave em uma nova linha.

Salvar.

Antes de remover a chave antiga, teste o acesso utilizando a nova chave.

---

# 7. Remover uma chave

Editar:

```bash
nano ~/.ssh/authorized_keys
```

Remover a linha correspondente à chave desejada.

Salvar.

---

# 8. Desabilitar autenticação por senha

Editar:

```bash
nano /etc/ssh/sshd_config
```

Localizar e alterar (ou adicionar) as seguintes opções:

```text
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
```

Salvar.

Reiniciar o serviço:

```bash
systemctl restart ssh
```

---

# 9. Testar antes de fechar a sessão atual

**Muito importante**

Não feche a sessão SSH atual.

Abra um **novo terminal** e execute:

```powershell
ssh orangepi
```

Confirme que o login funciona utilizando apenas a chave.

Somente após confirmar, encerre a sessão antiga.

---

# 10. (Opcional) Bloquear login direto do root

Caso futuramente seja criado um usuário administrador, recomenda-se impedir login direto do root.

Editar:

```bash
nano /etc/ssh/sshd_config
```

Alterar:

```text
PermitRootLogin no
```

ou

```text
PermitRootLogin prohibit-password
```

Reiniciar:

```bash
systemctl restart ssh
```

---

# Recuperação de acesso

Caso a chave seja perdida e ainda exista acesso físico à OrangePi (monitor e teclado, console serial ou outro método de administração), é possível restaurar o acesso.

## Reativar autenticação por senha

Editar:

```bash
nano /etc/ssh/sshd_config
```

Alterar:

```text
PasswordAuthentication yes
ChallengeResponseAuthentication yes
```

Reiniciar o SSH:

```bash
systemctl restart ssh
```

Após conseguir acessar novamente, gere um novo par de chaves, instale a nova chave pública em `~/.ssh/authorized_keys`, teste o acesso e, por fim, desabilite novamente a autenticação por senha.

---

# Testes

## Verificar o serviço SSH

```bash
systemctl status ssh --no-pager
```

---

## Confirmar que a porta 22 está aberta

```bash
ss -tlnp | grep :22
```

---

## Verificar a versão do SSH

No servidor:

```bash
ssh -V
```

---

## Confirmar autenticação por chave

No Windows:

```powershell
ssh -v orangepi
```

Resultado esperado:

```text
Offering public key:
Authentication succeeded (publickey)
```

---

## Verificar permissões

```bash
ls -la ~/.ssh

stat ~/.ssh

stat ~/.ssh/authorized_keys
```

Resultado esperado:

```text
~/.ssh                 -> 700

authorized_keys        -> 600
```

---

## Confirmar a configuração ativa do SSH

```bash
sshd -T | grep -E "passwordauthentication|pubkeyauthentication|permitrootlogin"
```

Resultado esperado:

```text
passwordauthentication no
pubkeyauthentication yes
permitrootlogin yes
```

Caso tenha desabilitado o login do root:

```text
permitrootlogin no
```

---

# Estado atual

* ✔ Chave SSH ED25519 criada
* ✔ Chave pública instalada na OrangePi
* ✔ Autenticação por chave funcionando
* ✔ Arquivo `config` configurado no Windows
* ✔ Login por senha desabilitado
* ✔ Permissões do SSH ajustadas corretamente
* ✔ Procedimento para troca de chaves documentado
* ✔ Procedimento de recuperação de acesso documentado
