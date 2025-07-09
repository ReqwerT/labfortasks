#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$BASE_DIR/scriptsdeb"
HOSTS="$SCRIPTS/hosts.ini"
PRESEED_SCRIPT="$BASE_DIR/preseed/auto_debian_install.sh"
TARGET_IP="192.168.121.145"

echo -n "Checking Ansible: "
if command -v ansible-playbook &>/dev/null; then
    echo "Found → $(ansible --version | head -n1)"
else
    echo "Not found. Installing Ansible..."
    sudo apt-get update -qq
    sudo apt-get install -y ansible python3-pip
    ansible-galaxy collection install community.libvirt
    sudo apt install -y sshpass
    echo "Ansible installed → $(ansible --version | head -n1)"
fi

echo -n "Checking Vagrant: "
if command -v vagrant &>/dev/null; then
    echo "Found → $(vagrant --version)"
else
    echo "Not found. Installing Vagrant..."
    sudo apt-get install -y curl gnupg2 software-properties-common
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update -qq
    sudo apt-get install -y vagrant
    echo "Vagrant installed → $(vagrant --version)"
fi

echo -n "Checking Libvirt: "
if command -v virsh &>/dev/null; then
    echo "Found → $(virsh --version)"
else
    echo "Not found. Installing Libvirt..."
    sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst libvirt-dev virt-manager
    sudo usermod -aG libvirt "$USER"
    sudo systemctl enable --now libvirtd
    echo "Libvirt installed → $(virsh --version)"
fi

echo "1-) Starting winvm..."
vagrant up winvm --provider=libvirt
echo " winvm is up."


echo "2-) shrink_disk.yml → copy_disks.yml → start_vm.yml → close_windows.yml"
ansible-playbook -i "$HOSTS" \
  "$SCRIPTS/shrink_disk.yml" \
  "$SCRIPTS/copy_disks.yml" \
  "$SCRIPTS/start_vm.yml" \
  "$SCRIPTS/close_windows.yml"
echo " Windows tasks completed."

echo "3-) Shutting down winvm..."
#vagrant halt winvm
echo " winvm is off."

sleep 30

echo "4-) Starting Debian preseed install in a new Konsole window..."
if command -v konsole &>/dev/null; then
  konsole --noclose -e "$PRESEED_SCRIPT" &
else
  gnome-terminal -- bash -c "$PRESEED_SCRIPT; read" &
fi

echo "5-) Waiting for SSH on $TARGET_IP..."
while ! nc -z "$TARGET_IP" 22 2>/dev/null; do
  sleep 5
done
echo " Debian installation finished, SSH is up."

echo "6-) install_qemu_on_debian.yml → start_vm_when_reboot_debian.yml → change_vda.yml → shutdown_lin.yml"
ansible-playbook -i "$HOSTS" \
  "$SCRIPTS/install_qemu_on_debian.yml" \
  "$SCRIPTS/start_vm_when_reboot_debian.yml" \
  "$SCRIPTS/change_vda.yml" \
  "$SCRIPTS/shutdown_lin.yml"
echo " Debian playbooks completed."

sleep 10
virsh undefine debian-in-windows --nvram || true
sleep 10

echo -e "\n Full workflow finished successfully."

