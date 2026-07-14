# OrangePi Zero 3 - SSH com autenticação por chave

Este guia configura o acesso remoto via **SSH utilizando autenticação por chave pública**, eliminando a necessidade de senha e aumentando significativamente a segurança do servidor.

Ao final deste guia será possível:

- gerar um par de chaves SSH no Windows;
- armazenar as chaves na pasta **Downloads**;
- instalar a chave pública na OrangePi;
- acessar o servidor utilizando apenas a chave privada;
- desabilitar autenticação por senha;
- recuperar o acesso caso a chave seja perdida.

---

# 1. Gerar uma chave SSH

No Windows, abra o **PowerShell**.

Execute:

```powershell
ssh-keygen -t ed25519 -C "azzor"
```

Quando o comando solicitar o local para salvar a chave, informe o caminho completo incluindo o nome do arquivo:

```text
C:\Users\azzor\Downloads\azzor_ed25519
```

> **Importante:** informe um **nome de arquivo**, e não apenas a pasta `Downloads`. Caso informe somente o diretório, o `ssh-keygen` exibirá um erro informando que o caminho já existe.

Será criado:

```text
C:\Users\azzor\Downloads\
├── azzor_ed25519
└── azzor_ed25519.pub
```

Onde:

- `azzor_ed25519` → chave privada (**NUNCA compartilhe**)
- `azzor_ed25519.pub` → chave pública (pode ser instalada no servidor)

Verifique se os arquivos foram criados:

```powershell
dir C:\Users\azzor\Downloads\azzor*
```

Resultado esperado:

```text
azzor_ed25519
azzor_ed25519.pub
```

---

# 2. Instalar a chave na OrangePi

Copiar automaticamente a chave pública para a área de transferência:

```powershell
Get-Content C:\Users\azzor\Downloads\azzor_ed25519.pub | Set-Clipboard
```

Conecte-se normalmente via SSH utilizando senha:

```powershell
ssh root@192.168.1.20
```

Criar o diretório caso não exista:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Criar o arquivo de chaves autorizadas:

```bash
touch ~/.ssh/authorized_keys
nano ~/.ssh/authorized_keys
```

Cole a chave pública em **uma única linha**.

Salvar.

Corrigir as permissões:

```bash
chmod 600 ~/.ssh/authorized_keys
```

Verificar o conteúdo:

```bash
cat ~/.ssh/authorized_keys
```

---

# 3. Testar o acesso utilizando a chave

No Windows:

```powershell
ssh -i C:\Users\azzor\Downloads\azzor_ed25519 root@192.168.1.20
```

Se tudo estiver correto, o login ocorrerá utilizando a chave privada.

Caso tenha definido uma **passphrase** durante a criação da chave, ela será solicitada.

---

# 4. Desabilitar autenticação por senha

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

# 5. Testar antes de fechar a sessão atual

**Muito importante**

Não feche a sessão SSH atual.

Abra um **novo terminal** no Windows e execute:

```powershell
ssh -i C:\Users\azzor\Downloads\azzor_ed25519 root@192.168.1.20
```

Confirme que o login funciona utilizando apenas a chave.

Somente após confirmar, encerre a sessão antiga.

---

# 6. (Opcional) Bloquear login direto do root

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

```bash
ssh -V
```

---

## Confirmar autenticação por chave

No Windows:

```powershell
ssh -v -i C:\Users\azzor\Downloads\azzor_ed25519 root@192.168.1.20
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

- ✔ Chave SSH ED25519 criada
- ✔ Chave pública instalada na OrangePi
- ✔ Autenticação por chave funcionando
- ✔ Login utilizando chave SSH funcionando
- ✔ Login por senha desabilitado
- ✔ Permissões do SSH ajustadas corretamente
- ✔ Procedimento de recuperação de acesso documentado
