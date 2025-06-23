#!/bin/bash

# === KULLANICI AYARLARI ===
VM_NAME="debian-in-windows"
VM_RAM=16384
VM_VCPUS=2
DISK_PATH="/var/lib/libvirt/images/extra-disk.qcow2"
DISK_PATH1="/var/lib/libvirt/images/windows11_default.img"
PRESEED_PORT=8000
PRESEED_DIR="/home/reqwert/Desktop/vagrantomv/ubuntuansible/preseed/"
PRESEED_FILE="preseed.cfg"
DEBIAN_MIRROR="http://ftp.debian.org/debian/dists/bookworm/main/installer-amd64/"
OS_VARIANT="debian11"

# === PORT KONTROLÜ ===
if lsof -i :$PRESEED_PORT &> /dev/null; then
    echo ">>> Uyarı: Port $PRESEED_PORT dolu, 8080'e geçiliyor."
    PRESEED_PORT=8080
fi

# === PRESEED SERVER BAŞLAT ===
echo ">>> Preseed dosyası HTTP sunucusunu başlatıyor (port $PRESEED_PORT)..."
cd "$PRESEED_DIR" || { echo "Preseed dizini bulunamadı!"; exit 1; }
python3 -m http.server $PRESEED_PORT &
HTTP_PID=$!
trap "echo '>>> HTTP sunucusu kapatılıyor'; kill $HTTP_PID" EXIT
sleep 2

# === PRESEED ERİŞİM TESTİ ===
echo ">>> Preseed dosyası erişim testi yapılıyor..."
if ! curl -s --head http://$(hostname -I | awk '{print $1}'):$PRESEED_PORT/$PRESEED_FILE | grep "200 OK" > /dev/null; then
    echo ">>> Hata: Preseed dosyasına erişilemiyor!"
    exit 1
fi

# === VARSA ESKİ VM'Yİ SİL ===
if virsh --connect qemu:///system dominfo "$VM_NAME" &> /dev/null; then
    read -p ">>> $VM_NAME mevcut, silinsin mi? [yes/no]: " confirm
    if [[ "$confirm" == "yes" ]]; then
        echo ">>> Var olan VM siliniyor: $VM_NAME"
        virsh --connect qemu:///system destroy "$VM_NAME"
        virsh --connect qemu:///system undefine "$VM_NAME"
    else
        echo ">>> İşlem iptal edildi."
        exit 0
    fi
fi

# === VIRT-INSTALL BAŞLAT ===
echo ">>> Virt-install başlıyor..."
virt-install \
  --name "$VM_NAME" \
  --memory "$VM_RAM" \
  --vcpus "$VM_VCPUS" \
  --disk path="$DISK_PATH",device=disk \
  --disk path="$DISK_PATH1",device=disk \
  --os-variant "$OS_VARIANT" \
  --location "$DEBIAN_MIRROR" \
  --network network=vagrant-libvirt \
  --graphics spice \
  --video qxl \
  --channel spicevmc \
  --check path_in_use=off \
  --extra-args "auto=true priority=critical url=http://$(hostname -I | awk '{print $1}'):$PRESEED_PORT/$PRESEED_FILE console=ttyS0,115200n8 serial \
                partman-auto/disk=/dev/vda partman-auto/init_automatically_partition=true \
                late_command='in-target bash -c \"echo -e \\\"auto enp1s0\niface enp1s0 inet static\naddress 192.168.121.145\nnetmask 255.255.255.0\ngateway 192.168.121.1\ndns-nameservers 8.8.8.8\\\" > /etc/network/interfaces\"'"


if [ $? -ne 0 ]; then
    echo ">>> Virt-install başarısız!"
    exit 1
fi

echo ">>> Debian kurulumu tamamlandı ve VM kapatıldı."
echo ">>> Diskler korunarak işlem başarıyla sonlandı ✅"


