#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -n "Checking xmlstarlet: "
if command -v xmlstarlet &>/dev/null; then
    echo "Found → $(xmlstarlet --version | head -n1)"
else
    echo "Not found. Installing xmlstarlet..."
    sudo apt-get update -qq
    sudo apt-get install -y xmlstarlet
    echo "xmlstarlet installed → $(xmlstarlet --version | head -n1)"
fi

echo -n "Checking rsync: "
if command -v rsync &>/dev/null; then
    echo "Found → $(rsync --version | head -n1)"
else
    echo "Not found. Installing rsync..."
    sudo apt-get update -qq
    sudo apt-get install -y rsync
    echo "rsync installed → $(rsync --version | head -n1)"
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

echo -n "Checking vagrant-libvirt plugin: "
if vagrant plugin list | grep -q 'vagrant-libvirt'; then
    version=$(vagrant plugin list | grep 'vagrant-libvirt' | awk '{print $2}')
    echo "Found → vagrant-libvirt ${version}"
else
    echo "Not found. Installing vagrant-libvirt plugin..."
    vagrant plugin install vagrant-libvirt
    echo "vagrant-libvirt plugin installed → $(vagrant plugin list | grep 'vagrant-libvirt')"
fi
