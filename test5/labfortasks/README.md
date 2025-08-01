# AUTOMATED LAB ENVIRONMENT (VAGRANT + ANSIBLE)

## Purpose

Using Ansible on the virtual machines I created with Vagrant:

- I created a system configured for automatic dual-booting.
- I used shared disks, regardless of the operating system being booted. Before the system installation began, I installed the OMV virtual machine on disk.vmdk and created disk1.vmdk to add an additional disk.
- I automatically accessed the OMV virtual machine from Windows within the shared folder I created with rsync.
- I enabled the OMV virtual machine to start automatically on every startup.
- I then copied my OMV disks to the OMV disk, which I formatted as exFAT.
- All of this can be done in about an hour with just the vagrant up command.



##  Steps I Followed

- First, to determine whether the user is logged in as session or system, I searched for the word session in the libvirt URI. If the word session is in the URI, I determine that the user is running as non-root and I retrieve the IP configuration information from virbr0. If the user is running as non-root and virbr0 is not active, I enter the root password and retrieve the subnet information from the default network. If the word session is not in the URI, this indicates that the user is running as root and that the virtual machine will run with qemu://system. In this case, I retrieve the subnet information from the default network.
- I specify the IP addresses of the Windows and dualboot-debian virtual machines by adding .10 to the end of the subnet information. To avoid any confusion, I initially set the IP address of the OMV virtual machine to .15. This allows me to easily install OpenMediaVault on my virtual machine using Ansible.
- Using the vagrant before trigger, I add the necessary IP information to my .ini files. This allows me to easily manage with Ansible.
- Using the Vagrant Before trigger, I automatically installed the OMV virtual machine using the preseed config file in disk.vmdk. After this installation was completed successfully, I successfully installed the OpenMediaVault tools on my OMV virtual machine via Ansible.
- After successfully installing OMV, I changed the IP configuration on the OMV virtual machine. My tests showed that when the IP configuration was set to static with extra-args, I couldn't access the virtual machine, even if I had initiated NAT with QEMU. The old configuration was interfering. Thanks to this change, I can now access it without any problems.
- After finishing work on the OMV virtual machine, I start the Windows virtual machine. I entered the autostart:false parameter on my Vagrant Windows machine. It doesn't automatically start when I type vagrantup, and thanks to the Ubuntu trigger, it works exactly when it needs to.
- I installed the latest version of QEMU on my Windows machine and enabled virtualization technologies.
- I shrank my physical disk by 20 GB for OMV.
- I formatted this disk in exFAT to make it accessible from Linux, macOS, and Windows.
- I copied the OMV image file and disk1.vmdk to this disk.
- I automatically placed the .ps1 and .bat files in their respective folders, which automatically start the OMV virtual machine when Windows starts.
- I added the 25 GB lastden.qcow2 disk to the Vagrantfile for a dual-boot Debian installation.
- I automatically installed Debian on this disk using Preseed and provided Ansible access by assigning it a static IP address.
- I installed QEMU within Debian with Ansible, mounted the OMV disk, and configured the systemd service to automatically start the OMV virtual machine every time Debian starts.

## Requirements

This system only requires the following three applications:

- `Virtualization Support`: Your computer must support virtualization and have virtual-within-virtual capabilities, which must be enabled in the BIOS. AMD processors have AMD-V, and Intel processors have VT-x. In bare-metal Linux, you can determine whether virtualization is enabled by typing the command `egrep -c '(vmx|svm)' /proc/cpuinfo` into a terminal. If the output is greater than `0`, virtualization is enabled on your computer. If it is `0`, virtualization support is not available or has not yet been activated.
- `Vagrant 2.4.7`: Our system uses two virtual machine configurations within a single Vagrantfile. I configured all steps using triggers to be executed with the vagrant up command. To run this lab environment smoothly, you must have Vagrant installed on your computer.
- `rsync`: Rsync must be installed for file shares
- `libvirt 9.0.0`: The virtual machines and provider I selected as providers are compatible with libvirt. You must have libvirt installed on your computer.
- `Vagrant-libvirt plugin 0.11.2`: In order for Vagrant to recognize libvirt on our system, the Vagrant libvirt plugin must be installed.
- `xmlstarlet`: At the end of all operations, xmlstartlet should be installed on our system, so that the installed Debian operating system is marked as bootable and set as the first disk.


> If you want to install all the requirements manually, run the following command in a root terminal. If you don't want to install manually, run the install_req_debian.sh file with root permissions. This file checks all for the Debian  requirements and installs them if they're missing.
  
  ```bash
  sudo apt update && sudo apt install -y \
    cpu-checker \
    rsync \
    libvirt-daemon-system \
    libvirt-clients \
    qemu-kvm \
    ruby-dev \
    xmlstarlet \
    egrep \
    dnsmasq \
    libxslt-dev \
    libxml2-dev \
    zlib1g-dev \
    libguestfs-tools \
    gcc \
    qemu-utils \
    make \
    vagrant
  
  # Install the specific version of the vagrant-libvirt plugin
  vagrant plugin install vagrant-libvirt --plugin-version 0.11.2
  
  # Enable and start libvirtd service
  sudo systemctl enable --now libvirtd
  
  # Add your user to the libvirt group for permission access
  sudo usermod -aG libvirt $(whoami)
  
  # Check virtualization support (should return a number > 0)
  egrep -c '(vmx|svm)' /proc/cpuinfo
  ```
  






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
- I observed that when I executed the `vagrant destroy` command after `vagrant up`, the default network information was deleted. To do this, I initially created a trigger using chattr +i to prevent the deletion of the default network, but I realized this method wasn't valid. After researching the virtual machines' IP configuration, I specified that I was using the default network by entering the following parameters:
  `libvirt__network_name: "default"` ,
  `libvirt__always_destroy: false` 
  I set the `libvirt__always_destroy` parameter, which is set to `true` by default in Vagrant, to `false` on both virtual machines. This prevented the `vagrant destroy -f` command from touching my default network. This method resolved the issue. I've added the details to the error table.
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

- If you want to read all report files, [click here](https://github.com/ReqwerT/labfortasks/blob/main/report.md)
- If you want to see error tables, [click here](https://github.com/ReqwerT/labfortasks/blob/main/errors.md)
