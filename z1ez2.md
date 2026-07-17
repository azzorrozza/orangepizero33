# Auditoria - OrangePi Zero 3
## Validação Completa - Tailscale + Unbound

Este documento realiza uma auditoria completa da configuração do OrangePi Zero 3 após a instalação do Tailscale (Exit Node + Subnet Router) e do Unbound.

> **Observação:** Todos os comandos abaixo são apenas de leitura. Nenhuma configuração será alterada.

---

# Informações do sistema

```bash
hostnamectl

uname -a

cat /etc/os-release
```

---

# Interfaces de rede

```bash
ip addr

ip route

networkctl status
```

---

# Sysctl

```bash
cat /etc/sysctl.d/99-tailscale.conf

sysctl net.ipv4.ip_forward

sysctl net.ipv6.conf.all.forwarding
```

---

# Tailscale

```bash
tailscale version

tailscale status

tailscale ip

tailscale debug prefs

tailscale metrics | head

tailscale netcheck
```

---

# Serviço tailscaled

```bash
systemctl status tailscaled --no-pager

systemctl is-enabled tailscaled

journalctl -u tailscaled -n 100 --no-pager
```

---

# Script do Subnet Router

```bash
ls -lah /etc/networkd-dispatcher/routable.d/

cat /etc/networkd-dispatcher/routable.d/50-tailscale-route

stat /etc/networkd-dispatcher/routable.d/50-tailscale-route

bash -n /etc/networkd-dispatcher/routable.d/50-tailscale-route && echo "Syntax OK"

journalctl -t tailscale-subnet-router -n 100 --no-pager
```

---

# networkd-dispatcher

```bash
systemctl status networkd-dispatcher --no-pager

systemctl is-enabled networkd-dispatcher

journalctl -u networkd-dispatcher -n 100 --no-pager
```

---

# UDP GRO

```bash
ethtool --version

systemctl status ethtool-end0.service --no-pager

systemctl is-enabled ethtool-end0.service

cat /etc/systemd/system/ethtool-end0.service

ethtool -k end0
```

---

# systemd-resolved

```bash
cat /etc/systemd/resolved.conf

systemctl status systemd-resolved --no-pager

resolvectl status

ls -l /etc/resolv.conf

readlink -f /etc/resolv.conf

cat /etc/resolv.conf
```

---

# Netplan

```bash
ls -lah /etc/netplan/

cat /etc/netplan/*.yaml

netplan get
```

---

# Unbound

```bash
unbound -V

systemctl status unbound --no-pager

systemctl is-enabled unbound

journalctl -u unbound -n 100 --no-pager
```

---

# Configuração do Unbound

```bash
cat /etc/unbound/unbound.conf.d/recursive.conf

unbound-checkconf

unbound-checkconf -o interface

unbound-checkconf -o port
```

---

# Trust Anchor

```bash
ls -lah /var/lib/unbound/

ls -l /var/lib/unbound/root.key

stat /var/lib/unbound/root.key
```

---

# Portas abertas

```bash
ss -lnptu
```

---

# DNS (Localhost)

```bash
dig @127.0.0.1 -p 5335 openai.com

dig @127.0.0.1 -p 5335 cloudflare.com

dig @127.0.0.1 -p 5335 sigok.verteiltesysteme.net

dig @127.0.0.1 -p 5335 dnssec-failed.org
```

---

# DNS (Rede Local)

```bash
dig @"$(hostname -I | awk '{print $1}')" -p 5335 openai.com
```

---

# Firewall

```bash
iptables -L -n -v

ip6tables -L -n -v
```

---

# Inicialização do sistema

```bash
systemd-analyze blame

systemd-analyze critical-chain
```

---

# Serviços habilitados

```bash
systemctl list-unit-files --state=enabled
```

---

# Estado geral do sistema

```bash
systemctl --failed
```

---

# Utilização de recursos

```bash
free -h

df -h

uptime

top -b -n1 | head -30
```

---

# Resultado esperado

Ao final da auditoria, espera-se encontrar:

- ✅ Sistema operacional atualizado e íntegro.
- ✅ Interface de rede configurada corretamente.
- ✅ IP Forward IPv4 e IPv6 habilitados.
- ✅ Tailscale ativo como Exit Node e Subnet Router.
- ✅ Rotas anunciadas corretamente.
- ✅ UDP GRO habilitado.
- ✅ networkd-dispatcher funcionando.
- ✅ systemd-resolved utilizando o Unbound como resolvedor local.
- ✅ Netplan impedindo o DHCP de sobrescrever o DNS.
- ✅ Unbound ativo e sem erros de configuração.
- ✅ DNSSEC validando corretamente (`dnssec-failed.org` retorna `SERVFAIL`).
- ✅ Consultas DNS locais e pela rede respondendo corretamente.
- ✅ Porta 5335 aberta para TCP e UDP.
- ✅ Regras do Tailscale presentes no iptables/ip6tables.
- ✅ Nenhum serviço com falha (`systemctl --failed`).
- ✅ Uso de memória, disco e CPU dentro do esperado.
