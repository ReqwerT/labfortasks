
# REPORT

## Task 1

### Automated System Development Using Vagrant-Ansible

**Prepared by: Seyfullah Kaya**

---

## Purpose and Requirements

- Our purpose in designing the system is to create a lab environment that will be used in future tasks and that is automatically started up. The reason why we did not try the tasks on baremetal is that our system may be damaged while performing some dangerous operations. Therefore, it would be best to run it in a virtual environment in terms of both our time and system security. However, running the lab environment may still cause us trouble. Therefore, I designed the entire lab environment that we created using ansible and scripts to be started up with just one command.

- We need some requirements to get the system up and running. I created the test environment on bare metal debian. Vagrant, libvirt and vagrant-libvirt plugins must be installed on bare metal. The "start_all.sh" script in the main directory I created checks the requirements in order and automatically installs them if there is anything missing. You can also perform the necessary installations manually. The stages will be available on github. Since our Windows machine will be nested-virt, I allocated 16GB RAM and 4 CPU cores. My Bare-metal machine will work entirely for ansible management. I assigned static IP addresses to both virtual machines (libvirt_winvm and dualboot debian). I will present all the configs to you in the following lines of the report. You can change the features from the relevant places according to your own needs.

 - Another problem for the system is that I could not give a static IP address to my dualboot debian virtual machine that I automatically set up with the preseed file I wrote. It preferred to assign this IP address with DHCP every time, and because of this problem, I could not manage my dual-boot debian virtual machine that I set up with my ansible machine and I could not load the requirements to that virtual machine and start it. Therefore, I wrote the IP settings in auto_debian_install.sh file's .I will explain the system’s yml playbooks and all the work they do in the next section completely and clearly.

---

## Operating the System and Its Functioning

To run the system, we first need to download the files from github. Then our "libvirt/start_all.sh" script will start the entire system.

```bash
cd /libvirt
chmod +x ./start_all.sh
./start_all.sh
```

This script:
- Checks vagrant, libvirt, and vagrant-libvirt plugin; installs if missing
- Starts Windows VM, runs provisioning:
  - Static IP 192.168.121.10
  - Pulls ConfigurationRemotingForAnsible.ps1
  - Runs install_qemu.ps1 (enables Hyper-V, installs QEMU)
  - Runs download.ps1 (installs Python, gdown, downloads disk.vmdk, creates disk1.vmdk)
  - Close windows when finish all steps.
- Starts Debian dualboot install:
  - Static IP 192.168.121.10
  - Runs /preseed/auto_debian_install.sh scripts:

### Ansible Playbooks

- `shrinkdisk.yml`: Shrinks 20GB space from Windows disk, formats as exFAT `D:` for OMV use.
- `copy_disks.yml`: Copies OMV disks (disk.vmdk, disk1.vmdk) to `D:` drive.
- `start_vm.yml`: Creates QEMU boot scripts for OMV, enables startup with Windows using WHPX accel, 4GB RAM, 2 disks, and port forwarding.
- `close_windows.yml`: Shuts down Windows VM to release resources.
- `install_qemu_on_debian.yml`: Installs QEMU in Debian virtual machine.
- `start_vm_when_reboot_debian.yml`: Configures OMV disk in `/etc/fstab`, sets up `qemu-vm.service` for nested VM autostart on every reboot (ports 8080, 8443, 2222).
- `change_vda.yml`: Fixes `/etc/fstab` to use `vda` instead of `vdb` for proper boot.

---  

### Script Files

- `start_all.sh`: A script file located in the libvirt root directory automatically executes all operations sequentially. After downloading the project, simply grant it run permissions and run ./start_all.sh. It will automatically handle the rest for you.
- `/preseed/auto_debian_install.sh`: This script creates a virtual machine named debian-in-windows by serving the preseed file located in the same folder. This virtual machine uses the lastden.qcow2 disk created with Vagrant as the primary disk and the winvm machine's main disk as the secondary disk. It automatically installs Debian on the entire lastden.qcow2 disk with preseed and assigns the IP address 192.168.121.10 to the virtual machine using the extra-args command. The second disk is used to identify the Windows bootloader as part of Grub. This allows GRUB to detect not only Debian but also the Windows operating system.
- `change_boot.sh`: This script, once all processes are complete, changes the boot order within our virtual machine. The second installed disk is set as bootable and selected as the first disk. This allows GRUB to launch when the virtual machine boots, giving us a choice. You can choose either Windows or Debian to access the OMV virtual machine.

---  


## System Access Table

| Machine          | Username        | Password         | Virt Level | IP Address       |
|------------------|------------------|------------------|------------|------------------|
| Windows          | vagrant          | vagrant          | 1          | 192.168.121.10  |
| Debian Dualboot  | user / root      | userpass / rootpass | 1       | 192.168.121.10  |
| OMV (nested)     | root / admin     | 1647 / sanbox    | 2          | 192.168.121.10:8080  |

**Virt Level 1** = regular VM — **Virt Level 2** = nested (OMV inside Debian/Windows)

---

## Results

  - As a result of these operations, a dual-boot structure was achieved within a single virtual machine. After the Vagrant Windows virtual machine was powered on, it was managed with Ansible, installed on the bare-metal platform, and automated operations were performed. As a result, access to the OMV interface via the 192.168.121.10:8080 connection was successfully established. The Windows machine was then shut down, and operations were initiated in a new terminal to automatically install Debian on the second disk. These operations accessed the preseed file served from the host machine and successfully installed Debian in the new virtual machine. Grub was installed successfully along with the installation. The installation was confirmed by continuously sending SSH requests to the host machine. If the SSH request was successful, the installation was confirmed successfully, and the necessary operations were performed automatically with Ansible. The Linux machine was then shut down, and the temporary virtual machine definition created was deleted. We now have a virtual machine with a dual-boot operating system, and regardless of the operating system we select, it automatically accesses the OMV disk, starts a virtual machine with that disk, and we can successfully access that virtual machine.

  - As a result of all these steps, our lab environment was automatically launched. Tests show that this environment was ready in approximately one hour. Regardless of the operating system selected, access to the commonly used exFAT-formatted OMV disks was seamless on all systems, and each time the virtual machine was restarted, the OMV virtual machine was automatically started within the virtual environment; access tests were completed successfully on both operating systems.

### OMV Disk and Repo
- [OMV Disk Download](https://drive.google.com/file/d/1Xf_O8pprBlkvgMcjBodDnoYdFOh6JFC9/view?usp=sharing)
- [GitHub Repo](https://github.com/ReqwerT/labfortasks/tree/main)

---

## Test System Specs

| Component     | Detail                 |
|---------------|------------------------|
| Model         | Asus fx706li-hx199     |
| CPU           | Intel Core i5 10300h   |
| RAM           | 32 GB DDR4             |
| Disk          | 480 GB M.2 SSD         |
| OS            | Baremetal Debian       |
| VT-x          | Enabled                |
