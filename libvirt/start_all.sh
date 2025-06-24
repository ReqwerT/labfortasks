#!/bin/bash
set -e

# Function to check command existence
check_command() {
  command -v "$1" &>/dev/null
}

# [0/4] Check for required dependencies
echo "[0/4] Checking required tools..."

MISSING=()

if ! check_command vagrant; then
  MISSING+=("vagrant")
fi

if ! check_command virsh; then
  MISSING+=("libvirt-bin / libvirt-clients")
fi

if ! vagrant plugin list | grep -q vagrant-libvirt; then
  MISSING+=("vagrant-libvirt plugin")
fi

if [ ${#MISSING[@]} -ne 0 ]; then
  echo "[!] The following required components are missing:"
  for item in "${MISSING[@]}"; do
    echo "  - $item"
  done

  read -p "Do you want to install them now? [y/N]: " choice
  case "$choice" in
    y|Y )
      echo "[*] Installing dependencies..."

      if ! check_command vagrant; then
        echo "Installing Vagrant..."
        sudo apt update
        sudo apt install -y vagrant
      fi

      if ! check_command virsh; then
        echo "Installing libvirt..."
        sudo apt install -y libvirt-daemon-system libvirt-clients qemu-kvm
      fi

      if ! vagrant plugin list | grep -q vagrant-libvirt; then
        echo "Installing vagrant-libvirt plugin..."
        vagrant plugin install vagrant-libvirt
      fi
      ;;
    * )
      echo "Aborting. Please install the missing dependencies and try again."
      exit 1
      ;;
  esac
else
  echo "[✓] All required tools are present."
fi

# [1/4] Check and create 'vagrant-libvirt' network if it doesn't exist
echo "[1/4] Checking 'vagrant-libvirt' libvirt network..."

if ! virsh net-info vagrant-libvirt &> /dev/null; then
  echo "Network 'vagrant-libvirt' not found. Creating..."

  cat <<EOF > /tmp/vagrant-libvirt.xml
<network>
  <name>vagrant-libvirt</name>
  <bridge name='virbr121' stp='on' delay='0'/>
  <forward mode='nat'/>
  <ip address='192.168.121.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.121.100' end='192.168.121.254'/>
    </dhcp>
  </ip>
</network>
EOF

  sudo virsh net-define /tmp/vagrant-libvirt.xml
  sudo virsh net-autostart vagrant-libvirt
  sudo virsh net-start vagrant-libvirt
  echo "[✓] 'vagrant-libvirt' network created and started."
else
  echo "[✓] Network 'vagrant-libvirt' already exists."
fi

# [2/4] Start Windows VM
echo "[2/4] Starting Windows VM (winvm)..."
vagrant up winvm

# [3/4] Start Ubuntu VM
echo "[3/4] Starting Ubuntu VM (ubuntu)..."
vagrant up ubuntu --provider=libvirt

echo "[✓] All virtual machines are up and running."
