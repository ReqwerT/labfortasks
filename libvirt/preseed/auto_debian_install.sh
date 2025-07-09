#!/bin/bash

# === USER SETTINGS ===
VM_NAME="debian-in-windows"
VM_RAM=16384
VM_VCPUS=2
DISK_PATH="/var/lib/libvirt/images/lastden.qcow2"
DISK_PATH1="/var/lib/libvirt/images/libvirt_winvm.img"
PRESEED_PORT=8000
PRESEED_DIR="$(dirname "$(realpath "$0")")"
PRESEED_FILE="preseed.cfg"
DEBIAN_MIRROR="http://ftp.debian.org/debian/dists/bookworm/main/installer-amd64/"
OS_VARIANT="debian11"

# === PORT CHECK ===
if lsof -i :$PRESEED_PORT &> /dev/null; then
    echo ">>> Warning: Port $PRESEED_PORT is in use, switching to 8080."
    PRESEED_PORT=8080
fi

# === START PRESEED SERVER ===
echo ">>> Starting preseed file HTTP server (port $PRESEED_PORT)..."
cd "$PRESEED_DIR" || { echo "Preseed directory not found!"; exit 1; }
python3 -m http.server $PRESEED_PORT &
HTTP_PID=$!
trap "echo '>>> Shutting down HTTP server'; kill $HTTP_PID" EXIT
sleep 2

# === PRESEED ACCESS TEST ===
echo ">>> Testing access to preseed file..."
if ! curl -s --head http://$(hostname -I | awk '{print $1}'):$PRESEED_PORT/$PRESEED_FILE | grep "200 OK" > /dev/null; then
    echo ">>> Error: Cannot access the preseed file!"
    exit 1
fi

# === DELETE OLD VM IF EXISTS ===
if virsh --connect qemu:///system dominfo "$VM_NAME" &> /dev/null; then
    read -p ">>> $VM_NAME already exists, delete it? [yes/no]: " confirm
    if [[ "$confirm" == "yes" ]]; then
        echo ">>> Deleting existing VM: $VM_NAME"
        virsh --connect qemu:///system destroy "$VM_NAME"
        virsh --connect qemu:///system undefine "$VM_NAME"
    else
        echo ">>> Operation cancelled."
        exit 0
    fi
fi

echo ">>> Starting virt-install..."
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
  --noautoconsole \
  --wait=-1 \
  --check path_in_use=off \
  --check none \
  --extra-args "
  auto=true priority=critical interface=auto
  netcfg/disable_autoconfig=true
  netcfg/use_autoconfig=false
  netcfg/get_ipaddress=192.168.121.145
  netcfg/get_netmask=255.255.255.0
  netcfg/get_gateway=192.168.121.1
  netcfg/get_nameservers=8.8.8.8
  netcfg/confirm_static=true
  url=http://$(hostname -I | awk '{print $1}'):8000/preseed.cfg
  console=ttyS0,115200n8 serial
"
if [ $? -ne 0 ]; then
    echo ">>> Virt-install failed!"
    exit 1
fi

echo ">>> Debian installation completed and VM shut down."
echo ">>> Disks preserved, operation completed successfully"
