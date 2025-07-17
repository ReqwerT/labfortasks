# AUTOMATED LAB ENVIRONMENT (VAGRANT + ANSIBLE)

## Purpose

Using Ansible within the virtual machines I created with Vagrant, I:

- Created a system configured for automatic dual boot,
- Provided automatic access to the OMV virtual machine via shared disks, regardless of the operating system booted, and ensured that the OMV VM automatically starts at every startup.
- All of this can be done in about an hour with just the `vagrant up` command.

## Steps I Performed

- Installed the latest version of QEMU on my Windows machine and enabled virtualization technologies.
- Shrink my physical disk by 20 GB for OMV.
- Formatted this disk in exFAT to make it accessible from Linux, macOS, and Windows.
- Copy the OMV image file to this disk and also created an additional 10 GB `.vmdk` disk.
- Automatically placed the `.ps1` and `.bat` files, which automatically start the OMV VM when Windows starts, in their respective folders.
- I added the 25GB disk `lastden.qcow2` to the `Vagrantfile` for the dualboot Debian installation.
- I automatically installed Debian on this disk using Preseed and provided Ansible access by assigning a static IP.
- I installed QEMU with Ansible within Debian, mounted the OMV disk, and defined the systemd service to automatically start the OMV VM whenever Debian boots.

## Requirements

This system only requires the following three applications:

- `Vagrant 2.4.7`: Our system uses two virtual machine configurations within a single Vagrantfile. I configured all steps using triggers to be executed with the vagrant up command. To run this lab environment smoothly, you must have Vagrant installed on your computer.
- `libvirt 9.0.0`: The virtual machines and provider I selected as providers are compatible with libvirt. You must have libvirt installed on your computer.
- `Vagrant-libvirt plugin 0.11.2`: In order for Vagrant to recognize libvirt on our system, the Vagrant libvirt plugin must be installed.
- `xmlstarlet`: At the end of all operations, xmlstartlet should be installed on our system, so that the installed Debian operating system is marked as bootable and set as the first disk.

> **Note:** I performed the entire process on a bare-metal Debian 12 system.

## Sidecar Note

For our Ansible machine, I used the Sidecar Ubuntu virtual machine. This machine's IP address is the dot.20 IP address of the libvirt default network on our system.

## System Initialization

```bash
# 1. Download the project to your system
git clone https://github.com/ReqwerT/labfortasks/

cd labfortasks/libvirt/

# 2. Run as ROOT
vagrant up
```

## System Operation

This Vagrantfile performs the following operations:

- Fetch default network information for libvirt
- Sets the IP address of the Windows virtual machine to dot.10 and the IP address of the Ansible Ubuntu virtual machine to dot.20
- After `vagrant up`, I observed that when we perform `vagrant destroy`, it deletes the default network information. I prevented this from happening by adding a trigger before `vagrant up`. It prevents the default network from being deleted with `chattr +i`. I'll add more information to the errors table.
- Using the `autostart: false` parameter, I prevented the Windows VM from automatically starting with `vagrant up`. Instead, I used `ubuntu.trigger.before:up` to start the Windows VM with the `vagrant up winvm` command before Ubuntu. This prevented my two VMs from starting simultaneously. My Windows VM would run first and perform the necessary operations, followed by my Ansible VM.
- Using the win.vm.provision command, I first pulled and ran the ConfigureRemotingForAnsible.ps1 file from GitHub so my Windows machine could be managed with Ansible. Then, using the win.vm.provision command, I ran the install_qemu.ps1 file I shared with Windows. With this file, I installed qemu on my Windows machine. Finally, using the win.vm.provision structure, I ran the download.ps1 file I shared with Windows. This file allowed me to download my OMV virtual machine from the internet. Because the virtual machine was large, I couldn't share it directly to GitHub. The hash values are available later in the article. After these steps, my Windows virtual machine is now ready.
- Once my Windows machine was ready, I added the win_ip value from the Vagrantfile to the hosts.ini file, along with another trigger, ubuntu.trigger.before :up. This way, the IP address I'd set to dot.10 from the default network for managing virtual machines with Ansible was written into the ini file before I even started.
- While preparing my Ubuntu virtual machine, I installed some software. These include:
  - `Ansible`: For remote management of Windows and Debian virtual machines
  - `sshpass`: Since I provide a password-based connection for Ansible, this needs to be installed.
- Using the ubuntu.trigger.after :up trigger, I ran some commands after my Ubuntu virtual machine was ready. These operations are:
  - `shrink_disk.yml`: Shrinks 20GB of disk space for OMV in our Windows virtual machine. Then, it formats this space in exFAT so that both Linux and Windows can read it.
  - `copy_disks.yml`: Copies the downloaded OMV disk and the 10GB of extra space we created to the D: drive we created.
  - `start_vm.yml`: Creates a ps1 script to automatically start our OMV virtual machine. This script creates a bat file in the startup folder to run it on every reboot. This way, whenever our Windows virtual machine restarts, our OMV virtual machine automatically starts up.
- And after these operations, we shut down our Windows machine with a new trigger using the vagrant halt winvm command.
- Using another trigger, we will automatically install Debian by running our preseed file on the lastden.qcow2 25GB disk that we added to our virtual machine;
  - By running the `auto_debian_install.sh` file, we first retrieve the libvirt default network information and assign the dot.10 IP address to this operating system using extra-args. We publish the preseed file, located in the same folder, to port 8000 (if this port is occupied, it automatically serves on port 8080). Next, we perform an access test on our preseed file. Once the access is successful, we use our prseed file to automatically obtain the dot.10 IP address and install the Debian operating system on our disk.
- After this process, the system enters a 60-second pause. Immediately afterward, the following playbooks are run to perform operations on our Debian virtual machine:
  - `install_qemu_on_debian.yml`: Installs qemu into Debian.
  - `start_vm_when_reboot_debian.yml`: Using this file, I created a service to access and start the OMV virtual machine every time Debian boots.
  - `change_vda.yml`: Using this file, we created a new virtual machine for Debian, and our primary disk in this virtual machine was our lastden.qcow2 disk (vda). Our OMV disk appeared as vdb2 within this virtual machine. However, in our actual virtual machine, our lastden.qcow2 disk is vdb2. In this case, our OMV disk will be in vda2. After all these operations, I use this playbook to change the mounted disk, set to vdb2, to vda2 in /etc/fstab. -shutdown_lin.yml: after all operations I shut down my debian machine.
- After all these steps are completed, we now have a dual-boot virtual machine. Whether you run Windows or Debian, our OMV virtual machine will boot in either configuration. Finally, we have two remaining steps. We'll undefine the Debian-in-Windows virtual machine we created, and with the change_boot.sh script, we'll make our lastden.qcow2 disk the first disk and make it bootable.
  - We undefine our Debian-in-Windows virtual machine using the virsh undefine debian-in-Windows --nvram command.
  - With the change_boot.sh script, using xmlstarlet, we change the boot order, mark our second disk as bootable, and activate the boot menu.

## Result

We now have a dual-boot virtual machine:

- Whether we boot into Windows or Debian,
- The OMV virtual machine starts automatically on both systems,
- For Windows, I can access OMV by entering the address http://{your_default_network}.10:8080 from another device on the network.
- For Debian, I can access OMV by entering the address http://{your_default_network}.10:8080 from another device on the network.

If you want to read all report files, [click here](https://github.com/ReqwerT/labfortasks/blob/main/report.md)
