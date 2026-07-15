
```
cp /etc/netplan/*.yaml /root/netplan-backup.yaml
```

```
nano /etc/netplan/*.yaml
```

```
# Added by Armbian
#
# Reference: https://netplan.readthedocs.io/en/stable/netplan-yaml/
#
# Let systemd-networkd manage all Ethernet devices on this system, but be configured by Netplan.

network:
  version: 2
  renderer: networkd

  ethernets:
    all-eth-interfaces:
      match:
        name: "e*"
      dhcp4: yes
      dhcp6: yes
      dhcp4-overrides:
        use-dns: false
      dhcp6-overrides:
        use-dns: false
      ipv6-privacy: yes

    all-lan-interfaces:
      match:
        name: "lan[0-9]*"
      dhcp4: yes
      dhcp6: yes
      dhcp4-overrides:
        use-dns: false
      dhcp6-overrides:
        use-dns: false
      ipv6-privacy: yes

    all-wan-interfaces:
      match:
        name: "wan[0-9]*"
      dhcp4: yes
      dhcp6: yes
      dhcp4-overrides:
        use-dns: false
      dhcp6-overrides:
        use-dns: false
      ipv6-privacy: yes
```

```
netplan generate
```

```
netplan apply
```


```
apt install libnss-resolve
```
