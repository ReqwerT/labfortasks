#!/bin/bash
set -e

echo "[+] Installing Ansible..."

# Update package lists and install dependencies
sudo apt update -y
sudo apt install -y software-properties-common python3-pip

# Add the official Ansible PPA and install Ansible
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Install pywinrm for Ansible to communicate with Windows hosts
echo "[+] Installing WinRM Python module..."
pip3 install pywinrm

# Disable host key checking for Ansible
export ANSIBLE_HOST_KEY_CHECKING=False

echo "[✓] Ansible and WinRM setup completed."

# Install QEMU on Debian
echo "[+] Installing QEMU on Debian..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/install_qemu_on_debian.yml
echo "[✓] QEMU installation completed."

echo "[+] Waiting for 10 seconds..."
sleep 10

echo "[+] Configuring VM autostart on reboot..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/start_vm_when_reboot_debian.yml
echo "[✓] OMV autostart configured."

echo "[+] Waiting for 30 seconds..."
sleep 30

ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/shutdown_lin.yml


# ------------------------------------------------------------------
echo "[+] Shutting down Linux guest..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/shutdown_lin.yml
echo "[✓] Linux guest shut down."

# ───────── Ping senkronizasyon bloğu ─────────
TARGET_IP="192.168.121.130"
echo "[i] $TARGET_IP adresi erişilebilir olana kadar bekleniyor..."

set +e                    # ping hatası betiği durdurmasın
while true; do
  if ping -c1 -W1 "$TARGET_IP" &>/dev/null; then
    echo "[✓] $TARGET_IP yanıt verdi. Devam ediliyor..."
    break
  fi
  sleep 5
done
set -e                    # hata-yakalama modunu yeniden aç
# ------------------------------------------------------------------

echo "[+] Waiting for 30 seconds..."
sleep 30

# Disk shrink for OMV
echo "[+] Starting disk shrink operation..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/shrink_disk.yml
echo "[✓] Disk shrink completed."

echo "[+] Waiting for 30 seconds..."
sleep 30

echo "[+] Copying disk to D drive..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/copy_disks.yml
echo "[✓] Disk successfully copied."

echo "[+] Waiting for 30 seconds..."
sleep 30

# Start VM script
echo "[+] Creating startup BAT file..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/start_vm.yml
echo "[✓] Startup BAT file successfully created."

echo "[+] Waiting for 30 seconds..."
sleep 30

# Shutdown Windows
echo "[+] Shutting down Windows machine..."
#ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/close_windows.yml
echo "[✓] Windows machine successfully shut down."

# Wait
echo "[+] Waiting for 30 seconds..."
sleep 30

sleep 100
#we should open dualboot on libvirt management screens an into debian. (disk2)

echo "Preseed ile debian kurulumu bekleniyor..."




