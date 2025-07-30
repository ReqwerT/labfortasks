#!/bin/bash

# === USER SETTINGS ===
VM_NAME="preseed-in-windows"
VM_RAM=16384
VM_VCPUS=2

# === PRESEED DIRECTORY & FILE ===
PRESEED_DIR="$(dirname "$(realpath "$0")")"
PRESEED_FILE="preseed_omv.cfg"

# === DETERMINE LIBVIRT URI AND MODE ===
if command -v virsh &>/dev/null; then
    uri=$(virsh uri)
else
    if [[ "$(id -u)" -ne 0 ]]; then
        uri="qemu:///session"
    else
        uri="qemu:///system"
    fi
fi

if [[ "$uri" == *session* ]]; then
    echo ">>> Detected session mode (uri=$uri)"
else
    echo ">>> Detected system mode (uri=$uri)"
fi

# === DISK PATHS (script dizininde) & CREATION ===
DISK1_PATH="$PRESEED_DIR/disk.vmdk"   # 10 GB kurulum diski
DISK2_PATH="$PRESEED_DIR/disk1.vmdk"      # 20 GB veri diski

# create VMDK disks if they don't exist
if [[ ! -f "$DISK1_PATH" ]]; then
  echo ">>> Creating 10 GB install disk: $DISK1_PATH"
  qemu-img create -f vmdk "$DISK1_PATH" 10G
fi
if [[ ! -f "$DISK2_PATH" ]]; then
  echo ">>> Creating 20 GB data disk:    $DISK2_PATH"
  qemu-img create -f vmdk "$DISK2_PATH" 20G
fi

# === PRESEED HTTP SERVER SETTINGS ===
PRESEED_PORT=8000
cd "$PRESEED_DIR" || { echo ">>> Error: Cannot cd to $PRESEED_DIR"; exit 1; }

# free port check
if lsof -i :$PRESEED_PORT &>/dev/null; then
    echo ">>> Port $PRESEED_PORT in use; switching to 8080."
    PRESEED_PORT=8080
fi

echo ">>> Starting HTTP server for preseed on port $PRESEED_PORT..."
python3 -m http.server $PRESEED_PORT &
HTTP_PID=$!
trap "echo '>>> Shutting down HTTP server'; kill $HTTP_PID" EXIT
sleep 2

# verify access
HOST_IP=$(hostname -I | awk '{print $1}')
echo ">>> Testing preseed access..."
if ! curl --silent --head "http://$HOST_IP:$PRESEED_PORT/$PRESEED_FILE" | grep "200 OK" &>/dev/null; then
    echo ">>> Error: Cannot access preseed file!"; exit 1
fi

# === NETWORK SETTINGS BASED ON MODE ===
if [[ "$uri" == *session* ]]; then
  echo ">>> Session mode: fetching virbr0 info"
  subnet_cidr=$(ip -4 addr show dev virbr0 \
                | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+/\d+')
  [[ -n "$subnet_cidr" ]] || { echo ">>> Error: virbr0 bulunamadı!"; exit 1; }
  SUBNET="${subnet_cidr%/*}"
  PREFIX="${subnet_cidr#*/}"
  NETMASK=$(python3 - <<EOF
import ipaddress
print(ipaddress.IPv4Network(f"0.0.0.0/{PREFIX}").netmask)
EOF
)
  GATEWAY="$SUBNET"
else
  echo ">>> System mode: fetching default libvirt network info"
  default_net_xml=$(virsh -c "$uri" net-dumpxml default 2>/dev/null)
  SUBNET=$(echo "$default_net_xml" \
           | grep -oP 'ip address=["'\'']\K[\d.]+(?=["'\''])')
  NETMASK=$(echo "$default_net_xml" \
           | grep -oP 'netmask=["'\'']\K[\d.]+(?=["'\''])')
  [[ -n "$SUBNET" && -n "$NETMASK" ]] || { echo ">>> Error: default ağ bulunamadı!"; exit 1; }
  GATEWAY="$SUBNET"
fi

STATIC_IP="${SUBNET%.*}.15"
echo ">>> Using IP = $STATIC_IP   Gateway = $GATEWAY   Netmask = $NETMASK"

# === CLEAN UP ANY EXISTING VM ===
if virsh --connect "$uri" dominfo "$VM_NAME" &>/dev/null; then
    read -p ">>> $VM_NAME exists. Delete it? [yes/no]: " confirm
    [[ "$confirm" == "yes" ]] || { echo ">>> Operation cancelled."; exit 0; }
    echo ">>> Deleting existing VM..."
    virsh --connect "$uri" destroy "$VM_NAME" &>/dev/null || true
    virsh --connect "$uri" undefine "$VM_NAME"
fi

# === PREPARE NETWORK ARG FOR virt-install ===
MACADDR=$(printf '52:54:00:%02x:%02x:%02x' \
    $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
if [[ "$uri" == *session* ]]; then
    NETWORK_ARG="--network bridge=virbr0,mac=${MACADDR},model=virtio"
else
    NETWORK_ARG="--network network=default,mac=${MACADDR},model=virtio"
fi

# === RUN virt-install ===
virt-install \
  --connect "$uri" \
  --name "$VM_NAME" \
  --memory "$VM_RAM" \
  --vcpus "$VM_VCPUS" \
  --disk path="$DISK1_PATH",format=vmdk,device=disk \
  --disk path="$DISK2_PATH",format=vmdk,device=disk \
  --os-variant "debian11" \
  --location "http://ftp.debian.org/debian/dists/bookworm/main/installer-amd64/" \
  $NETWORK_ARG \
  --graphics spice --video qxl --channel spicevmc \
  --noautoconsole --wait -1 --check path_in_use=off --check none \
  --extra-args "
    auto=true priority=critical interface=auto
    netcfg/disable_autoconfig=true netcfg/use_autoconfig=false
    netcfg/get_ipaddress=$STATIC_IP
    netcfg/get_netmask=$NETMASK
    netcfg/get_gateway=$GATEWAY
    netcfg/get_nameservers=8.8.8.8
    netcfg/confirm_static=true
    url=http://$HOST_IP:$PRESEED_PORT/$PRESEED_FILE
    console=ttyS0,115200n8 serial
"

if [ $? -ne 0 ]; then
    echo ">>> Virt-install failed!"; exit 1
fi

echo ">>> Debian/OMV installation complete; VM has shut down."
echo ">>> 10 GB disk: $DISK1_PATH"
echo ">>> 20 GB disk: $DISK2_PATH"
