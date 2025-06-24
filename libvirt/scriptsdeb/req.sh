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
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/close_windows.yml
echo "[✓] Windows machine successfully shut down."

# Wait
echo "[+] Waiting for 30 seconds..."
sleep 30

# Run Debian installer
echo "[+] Starting dual-boot installation..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/run_preseed.yml
echo "[✓] Debian installation (preseed) completed."

sleep 100
#we should open dualboot on libvirt management screens an into debian. (disk2)

echo "[+] Starting dual-boot network setup..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/run.yml
echo "[✓] Debian installation (preseed) completed."

echo "[+] Waiting for 10 seconds..."
sleep 10


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


echo "[+] Changing vda mount configuration..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/change_vda.yml
echo "[✓] vda mount configured."

echo "[+] Waiting for 10 seconds..."
sleep 10


echo "[+] Updating IP address configuration..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/delete_enp1s0.yml
echo "[✓] IP address configuration updated."

echo "[+] Waiting for 10 seconds..."
sleep 10


echo "[+] Shutting down Linux..."
#ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/shutdown_lin.yml
echo "[✓] Linux shut down."

echo "[+] Waiting for 10 seconds..."
sleep 10


echo "[+] Enabling dualboot (inside baremetal)..."
ansible-playbook -i /vagrant/scriptsdeb/hosts.ini /vagrant/scriptsdeb/enable_dualboot_on_baremetal.yml
echo "[✓] Dualboot configured."


