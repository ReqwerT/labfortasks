#!/bin/bash
set -e

# Function to check command existence
check_command() {
  command -v "$1" &>/dev/null
}

# -------------------------------------------------------------
# [0/5] Check for required dependencies
# -------------------------------------------------------------
echo "[0/5] Checking required tools..."

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

if ! check_command sshd; then
  MISSING+=("openssh-server")
fi

if [ ${#MISSING[@]} -ne 0 ]; then
  echo "[!] The following required components are missing:"
  printf '  - %s\n' "${MISSING[@]}"

  read -p "Do you want to install them now? [y/N]: " choice
  case "$choice" in
    y|Y )
      echo "[*] Installing dependencies..."

      # Vagrant
      if ! check_command vagrant; then
        echo "Installing Vagrant..."
        sudo apt update
        sudo apt install -y vagrant
      fi

      # Libvirt + QEMU
      if ! check_command virsh; then
        echo "Installing libvirt..."
        sudo apt install -y libvirt-daemon-system libvirt-clients qemu-kvm
      fi

      # vagrant-libvirt plugin
      if ! vagrant plugin list | grep -q vagrant-libvirt; then
        echo "Installing system packages for vagrant-libvirt plugin..."
        sudo apt install -y ruby-dev libxml2-dev libxslt1-dev zlib1g-dev build-essential pkg-config libguestfs-tools

        echo "Installing vagrant-libvirt plugin (with system libxml)..."
        VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 \
        NOKOGIRI_USE_SYSTEM_LIBRARIES=1 \
        vagrant plugin install vagrant-libvirt
      fi

      # OpenSSH Server
      if ! check_command sshd; then
        echo "Installing OpenSSH server..."
        sudo apt install -y openssh-server
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

# -------------------------------------------------------------
# [1/5] Ensure SSH service is active & root login enabled
# -------------------------------------------------------------
echo "[1/5] Configuring SSH server..."

# 1.1 Enable root login if not already
sudo sed -i \
  -e 's/^[#[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' \
  -e '$aPermitRootLogin yes' \
  /etc/ssh/sshd_config

# 1.2 Restart SSH service
sudo systemctl enable ssh
sudo systemctl restart ssh

# 1.3 Check root password status; if NP (no password) then prompt
if sudo passwd -S root | grep -q " NP "; then
  echo "Root account has no password set. Please create one now."
  sudo passwd root
fi

echo "SSH server ready — root login permitted."

# -------------------------------------------------------------
# [2/5] Check and create 'vagrant-libvirt' network if needed
# -------------------------------------------------------------
echo "[2/5] Checking 'vagrant-libvirt' libvirt network..."
sudo apt install expect
if ! virsh net-info vagrant-libvirt &>/dev/null; then
  echo "Network 'vagrant-libvirt' not found. Creating..."

  cat <<EOF >/tmp/vagrant-libvirt.xml
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

  sudo virsh net-define   /tmp/vagrant-libvirt.xml
  sudo virsh net-autostart vagrant-libvirt
  sudo virsh net-start    vagrant-libvirt
  echo "[✓] 'vagrant-libvirt' network created and started."
else
  echo "[✓] Network 'vagrant-libvirt' already exists."
fi

# -------------------------------------------------------------
# [3/5] Start Windows VM
# -------------------------------------------------------------
echo "[3/5] Starting Windows VM (winvm)..."
vagrant up winvm

# -------------------------------------------------------------
# [4/5] Start Ubuntu VM
# -------------------------------------------------------------
echo "[4/5] Starting Ubuntu VM (ubuntu)..."
vagrant up ubuntu --provider=libvirt

# -------------------------------------------------------------
# [5/5] Done
# -------------------------------------------------------------
echo "[✓] All virtual machines are up and running."
