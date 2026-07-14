# OrangePi Zero 3 - Unbound Recursive DNS + DNSSEC

Este guia configura a OrangePi Zero 3 para utilizar o **Unbound** como servidor DNS recursivo local, com **cache**, **DNSSEC** e integração correta com o **systemd-resolved**.

O servidor passa a resolver consultas diretamente na Internet, sem depender de servidores públicos (Cloudflare, Google, Quad9, etc.), enquanto o sistema operacional continua utilizando o `systemd-resolved` apenas como gerenciador da resolução local.

---

# 1. Instalar o Unbound

> **Importante (Debian 13 / Armbian Trixie):**
>
> Além do Unbound, instale também o pacote **dns-root-data**. Ele fornece o arquivo `/usr/share/dns/root.key`, utilizado pelo helper do Debian para atualizar automaticamente a Trust Anchor durante o boot.
>
> Sem esse pacote o serviço funciona normalmente, porém o `ExecStartPre=root_trust_anchor_update` termina com `status=1/FAILURE`.

Instalação:

```bash
apt install -y unbound unbound-anchor dns-root-data dnsutils
```

Habilitar o serviço:

```bash
systemctl enable unbound
```

---

# 2. Liberar a porta 53

Por padrão o **systemd-resolved** ocupa a porta 53 através do DNS Stub Listener.

Desabilite apenas o Stub, mantendo o serviço ativo.

Editar:

```bash
nano /etc/systemd/resolved.conf
```

Adicionar (ou alterar):

```ini
[Resolve]
DNSStubListener=no
```

Reiniciar:

```bash
systemctl restart systemd-resolved
```

Confirmar:

```bash
ss -lnptu | grep :53
```

A saída **não deve** mostrar nada utilizando a porta **53**.

O `systemd-resolved` continuará escutando apenas na porta **5355**.

---

# 3. Configurar o Unbound

Editar:

```bash
nano /etc/unbound/unbound.conf.d/recursive.conf
```

Conteúdo:

```conf
server:
    module-config: "validator iterator"

    interface: 0.0.0.0
    interface: ::0

    port: 53

    do-ip4: yes
    do-ip6: yes

    do-udp: yes
    do-tcp: yes

    prefer-ip6: no

    hide-identity: yes
    hide-version: yes

    harden-glue: yes
    harden-dnssec-stripped: yes

    qname-minimisation: yes

    prefetch: yes
    prefetch-key: yes

    rrset-roundrobin: yes

    cache-min-ttl: 300
    cache-max-ttl: 86400

    msg-cache-size: 32m
    rrset-cache-size: 64m

    outgoing-range: 128
    num-threads: 1

    so-rcvbuf: 4m
    so-sndbuf: 4m

    unwanted-reply-threshold: 10000

    minimal-responses: yes

    use-caps-for-id: no

    edns-buffer-size: 1232

    access-control: 127.0.0.0/8 allow
    access-control: ::1 allow
    access-control: 192.168.1.0/24 allow
    access-control: 100.64.0.0/10 allow

    verbosity: 1
```

> **Ajuste a rede `192.168.1.0/24` conforme sua LAN.**

---

# 4. Inicializar a Trust Anchor (DNSSEC)

Na primeira instalação o arquivo ainda não existe.

Criar o diretório:

```bash
mkdir -p /var/lib/unbound
```

Gerar a Trust Anchor:

```bash
unbound-anchor -a /var/lib/unbound/root.key
```

Corrigir permissões:

```bash
chown unbound:unbound /var/lib/unbound/root.key
chmod 644 /var/lib/unbound/root.key
```

Verificar:

```bash
ls -l /var/lib/unbound/root.key
```

Resultado esperado:

```text
-rw-r--r-- 1 unbound unbound ... /var/lib/unbound/root.key
```

---

# 5. Validar a configuração

```bash
unbound-checkconf
```

Verificar também:

```bash
unbound-checkconf -o interface
unbound-checkconf -o port
```

Resultado esperado:

```text
0.0.0.0
::0
53
```

---

# 6. Iniciar o serviço

```bash
systemctl restart unbound
```

Verificar:

```bash
systemctl status unbound --no-pager
```

Resultado esperado:

```text
Active: active (running)
```

---

# 7. Verificar o helper da Trust Anchor

O helper do Debian executa automaticamente:

```text
/usr/libexec/unbound-helper root_trust_anchor_update
```

O comando deve retornar sucesso:

```bash
/usr/libexec/unbound-helper root_trust_anchor_update
echo $?
```

Resultado esperado:

```text
0
```

Se retornar:

```text
1
```

verifique se o pacote foi instalado:

```bash
dpkg -l dns-root-data
```

Também confirme a existência do arquivo:

```bash
ls -l /usr/share/dns/root.key
```

Caso esse arquivo não exista, instale:

```bash
apt install dns-root-data
```

Sem esse pacote, o helper falha porque tenta copiar um arquivo inexistente:

```text
/usr/share/dns/root.key
```

Isso gera:

```text
ExecStartPre=root_trust_anchor_update
status=1/FAILURE
```

Mesmo com o Unbound funcionando normalmente.

Após instalar `dns-root-data`, o helper passa a funcionar corretamente.

---

# 8. Configurar o resolvedor do sistema

**Não substitua o `/etc/resolv.conf`.**

Mantenha o `systemd-resolved` gerenciando esse arquivo.

Verifique:

```bash
ls -l /etc/resolv.conf
```

Ele deve apontar para:

```text
/run/systemd/resolve/stub-resolv.conf
```

ou

```text
/run/systemd/resolve/resolv.conf
```

Mesmo com o Stub desabilitado, isso **não interfere** no funcionamento do Unbound.

---

# Testes

## Testar o próprio Unbound

```bash
dig @127.0.0.1 openai.com
```

---

## Testar pela interface da LAN

```bash
dig @192.168.1.20 openai.com
```

(Substitua pelo IP da OrangePi.)

Na primeira consulta o tempo costuma ser maior.

Na segunda consulta o resultado normalmente vem do cache.

---

## Testar DNSSEC

```bash
dig @127.0.0.1 dnssec-failed.org
```

Resultado esperado:

```text
status: SERVFAIL
```

Isso confirma que a validação DNSSEC está funcionando.

---

## Verificar a porta 53

```bash
ss -lnptu | grep :53
```

Resultado esperado:

```text
udp   ... 0.0.0.0:53
udp   ... [::]:53
tcp   ... 0.0.0.0:53
tcp   ... [::]:53
```

Todos pertencentes ao processo **unbound**.

O `systemd-resolved` continuará utilizando apenas a porta **5355**.

---

## Verificar estatísticas

```bash
unbound-control stats_noreset
```

Você deverá observar, por exemplo:

- `cachehits`
- `cachemiss`
- `recursivereplies`

Esses contadores aumentam conforme o servidor é utilizado.

---

# Funcionamento

Após a configuração:

- O Unbound escuta na porta **53** para IPv4 e IPv6.
- O `systemd-resolved` permanece ativo para gerenciamento da resolução local e integração com DHCP.
- O DNS Stub Listener permanece desabilitado.
- Clientes da LAN podem utilizar a OrangePi como servidor DNS.
- As consultas são resolvidas diretamente na Internet.
- As respostas passam por validação DNSSEC.
- O cache reduz significativamente o tempo das consultas subsequentes.
- A Trust Anchor é atualizada automaticamente pelo helper do Debian (quando o pacote `dns-root-data` está instalado).

---

# Estado atual

- ✔ Unbound instalado
- ✔ dns-root-data instalado
- ✔ Porta 53 liberada para o Unbound
- ✔ systemd-resolved mantido ativo
- ✔ DNS Stub desabilitado
- ✔ Trust Anchor inicializada
- ✔ Atualização automática da Trust Anchor funcionando
- ✔ Servidor recursivo funcionando
- ✔ Cache habilitado
- ✔ DNSSEC funcionando
- ✔ Consultas pela LAN funcionando
- ✔ Serviço iniciado automaticamente no boot
