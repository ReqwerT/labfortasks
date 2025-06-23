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

# Disk shrink for OMV
echo "[+] Disk shrink işlemi başlatılıyor..."
ansible-playbook -i /vagrant/scripts/hosts.ini /vagrant/scripts/shrink_disk.yml
echo "[✓] Disk shrink tamamlandı."

# Copy disk
echo "[+] Disk D sürücüsüne kopyalanıyor..."
ansible-playbook -i /vagrant/scripts/hosts.ini /vagrant/scripts/copy_disks.yml
echo "[✓] Disk başarıyla kopyalandı."

# Start VM script
echo "[+] Startup BAT dosyası oluşturuluyor..."
ansible-playbook -i /vagrant/scripts/hosts.ini /vagrant/scripts/start_vm.yml
echo "[✓] Startup BAT dosyası başarıyla oluşturuldu."

# Shutdown Windows
echo "[+] Windows makinesi kapatılıyor..."
ansible-playbook -i /vagrant/scripts/hosts.ini /vagrant/scripts/close_windows.yml
echo "[✓] Windows makinesi başarıyla kapatıldı."

# Wait
echo "[+] 30 saniye bekleniyor..."
sleep 30

# Run Debian installer
echo "[+] Dual-boot  kurulumu başlatılıyor..."
ansible-playbook -i /vagrant/scripts/hosts.ini /vagrant/scripts/run_preseed.yml
echo "[✓] Debian kurulumu (preseed) tamamlandı."

sleep 100
#we should open dualboot on libvirt management screens an into debian. (disk2)

echo "[+] Dual-boot  ip kurulumu başlatılıyor..."
ansible-playbook -i /vagrant/scripts/hosts.ini /vagrant/scripts/run.yml
echo "[✓] Debian kurulumu (preseed) tamamlandı."

# Install QEMU on Debian
echo "[+] QEMU debian a kuruluyor..."
ansible-playbook -i /vagrant/scripts/hosts.ini /vagrant/scripts/install_qemu_on_debian.yml
echo "[✓] QEMU kurulumu tamamlandı."


echo "[+] VM Açılışı ayarlanıyor kuruluyor..."
ansible-playbook -i /vagrant/scripts/hosts.ini /vagrant/scripts/start_vm_when_reboot_debian.yml
echo "[✓] OMV Açılışı ayarlandı."
