#!/usr/bin/expect -f
set timeout 30
spawn virsh console debian-in-windows
expect {
  "Escape character is" { send "\r" }
}
expect {
  "login:" { send "root\r" }
}
expect {
  "Password:" { send "rootpass\r" }
}
expect {
  "#" {
    send "cat > /etc/network/interfaces <<EOF\r"
    send "auto lo\r"
    send "iface lo inet loopback\r"
    send "\r"
    send "auto enp1s0\r"
    send "iface enp1s0 inet static\r"
    send "  address 192.168.121.145\r"
    send "  netmask 255.255.255.0\r"
    send "  gateway 192.168.121.1\r"
    send "  dns-nameservers 8.8.8.8\r"
    send "\r"
    send "auto enp8s0\r"
    send "iface enp8s0 inet static\r"
    send "  address 192.168.121.145\r"
    send "  netmask 255.255.255.0\r"
    send "  gateway 192.168.121.1\r"
    send "  dns-nameservers 8.8.8.8\r"
    send "EOF\r"
    send "\r"
    send "ip addr flush dev enp1s0\r"
    send "ip addr flush dev enp8s0\r"
    send "systemctl restart networking\r"
    send "exit\r"
  }
}
expect eof
