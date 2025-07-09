# AUTOMATED LAB ENVIRONMENT (VAGRANT + ANSIBLE)

## Purpose

Using Ansible within the virtual machines I created with Vagrant, I:

- Created a system configured for automatic dual boot,
- Provided automatic access to the OMV virtual machine via shared disks, regardless of the operating system booted, and ensured that the OMV VM automatically starts at every startup.

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

- Vagrant 2.4.7
- libvirt 9.0.0
- Ansible 2.14.18

> **Note:** I performed the entire process on a bare-metal Debian 12 system.

## Sidecar Note

I initially tried using a sidecar Ansible virtual machine, but because it created additional complexity and occasionally crashed the system, I continued with Ansible directly on the host machine. I can also re-integrate the sidecar structure if desired.

## System Initialization

```bash
# 1. Download the project to your system
git clone https://github.com/ReqwerT/labfortasks/
cd labfortasks/libvirt/

# 2. Give execution permission to the startup script
chmod +x start_all.sh

# 3. Run as ROOT
sudo ./start_all.sh
```

This script performs the following operations:

- Checks requirements and installs them if they are missing.
- Starts virtual machines.
- Runs Ansible playbooks.

## System Operation

### 1. Requirement Check

If any programs are missing, the script automatically installs them.

### 2. Starting the `winvm` Virtual Machine

- Static IP: `192.168.121.130`
- Triggering custom shell scripts in the `Vagrantfile`:
- Sharing the `/images` and `/libvirt/scriptswin` folders.
- Remotely loading the `ConfigureRemotingForAnsible.ps1` file.
- Using `install_qemu.ps1`:
- Installing QEMU.
- Enabling Hyper-V, WSL, and Virtualization.
- Downloading the OMV `.vmdk` file with `download.ps1`.
- Creating an additional 10 GB `.vmdk` disk.
- Assigning 16 GB of RAM and 4 CPU cores to the Windows VM.
- Adding the `lastden.qcow2` disk for the Debian installation.

### 3. Automating the Windows Side with Ansible

- `shrink_disk.yml`: Shrinks the 20 GB disk and formats it as `D:` in `exFAT` format.
- `copy_disks.yml`: Copys the OMV disks to the `D:` drive.
- `start_vm.yml`:
- Saved the QEMU `.ps1` config file to the `C:/vagrant_vm_boot` folder.
- Added the `.bat` file that runs this script to the `Startup` folder.
- OMV can be accessed via 192.168.121.130:8080.
- `close_windows.yml`: Shuts down the Windows VM.
- Then waits 30 seconds.

### 4. Installing Debian Automatically with Preseed

- Run `/preseed/auto_debian_install.sh` in a new terminal.
- Serve `preseed.cfg` over HTTP on port 8000.
- Install the VM using the `virsh` commands.
- Set a static IP address via `extra-args`.
- To enable GRUB to recognize other operating systems, I used the `only_debian=false` and `with_other_os boolean true` commands.
- Installing Debian takes about 30 minutes.
- After installation:
- The Windows disk is seen as `vdb`, and the OMV disk is seen as `vdb2`.
- Added the mount entry to `/etc/fstab`.

### 5. Completing the Automation in Debian

- When SSH access is enabled, I understand that the Debian installation has completed successfully, and the script performs the following steps in sequence:
- QEMU is installed with `install_qemu_on_debian.yml`.
- Systemd service is installed with `start_vm_when_reboot_debian.yml`, and I create the service that will start the QEMU virtual machine every time Debian restarts.
- Fstab is updated with `change_vda.yml` so that the disk path is `vda2` instead of `vdb2`.
- Shut down the Debian VM with `shutdown_lin.yml`.

### 6. Final Step: Removing the Temporary VM

- Delete the temporary VM definition defined for the Debian installation with the `virsh undefine debian-in-windows` command.

## Result

We now have a dual-boot virtual machine:

- Whether we boot into Windows or Debian,
- The OMV virtual machine starts automatically on both systems,
- For Windows, I can access OMV by entering the address http://192.168.121.130:8080 from another device on the network.
- For Debian, I can access OMV by entering the address http://192.168.121.145:8080 from another device on the network.
