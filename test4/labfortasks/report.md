
# REPORT

## Task 1

### Automated System Development Using Vagrant-Ansible

**Prepared by: Seyfullah Kaya**

---

## Purpose and Requirements

- Our purpose in designing the system is to create a lab environment that will be used in future tasks and that is automatically started up. The reason why we did not try the tasks on baremetal is that our system may be damaged while performing some dangerous operations. Therefore, it would be best to run it in a virtual environment in terms of both our time and system security. However, running the lab environment may still cause us trouble. Therefore, I designed the entire lab environment that we created using ansible and scripts to be started up with just one command.

- We need some requirements to get the system up and running. I created the test environment on bare metal Debian. The Vagrant, libvirt, and vagrant-libvirt plugins must be installed on the bare metal. If I enter "vagrant up" in the /libvirt directory I created with root access, the system will automatically start up. Since our Windows machine will be nested (nested-virt), I allocated 16 GB of RAM and 4 CPU cores. My bare metal machine will be run entirely for Ansible management. I assigned static IP addresses to both virtual machines (libvirt_winvm and dual-boot Debian) using the default libvirt network on your computer, using dot.10. I will present all the configurations in the following sections of the report. You can change the properties here to suit your needs.

 - Another problem for the system is that I could not give a static IP address to my dualboot debian virtual machine that I automatically set up with the preseed file I wrote. It preferred to assign this IP address with DHCP every time, and because of this problem, I could not manage my dual-boot debian virtual machine that I set up with my ansible machine and I could not load the requirements to that virtual machine and start it. Therefore, I wrote the IP settings in auto_debian_install.sh file's .I will explain the system’s yml playbooks and all the work they do in the next section completely and clearly.

---

## Operating the System and Its Functioning

To run the system, we first need to download the files from github. We should go to the libvirt folder with the terminal and type `vagrant up` as `root`.

```bash
cd /libvirt
vagrant up
```

This command:
- Starts ubuntu VM with triggers:
  - First, run the Windows VM with the before up trigger.
  - Windows vm pulls ConfigurationRemotingForAnsible.ps1 from github and runs it
  - Runs install_qemu.ps1 (enables Hyper-V, installs QEMU)
  - Runs download.ps1 (installs Python, gdown, downloads disk.vmdk, creates disk1.vmdk)
  - Close windows when finish all steps.
- Starts Debian dualboot install:
  - Static IP {your_default_network}.10
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

- `install_req_debian.sh`: This script automatically installs the necessary Debian installations. You can run this script directly to perform these installations automatically, or you can do it manually.
- `/preseed/auto_debian_install.sh`: This script creates a virtual machine named debian-in-windows by serving the preseed file located in the same folder. This virtual machine uses the lastden.qcow2 disk created with Vagrant as the primary disk and the winvm machine's main disk as the secondary disk. It automatically installs Debian on the entire lastden.qcow2 disk with preseed and assigns the IP address {your_default_network}.10 to the virtual machine using the extra-args command. The second disk is used to identify the Windows bootloader as part of Grub. This allows GRUB to detect not only Debian but also the Windows operating system.
- `change_boot.sh`: This script, once all processes are complete, changes the boot order within our virtual machine. The second installed disk is set as bootable and selected as the first disk. This allows GRUB to launch when the virtual machine boots, giving us a choice. You can choose either Windows or Debian to access the OMV virtual machine.

---  


## System Access Table

| Machine          | Username        | Password         | Virt Level | IP Address       |
|------------------|------------------|------------------|------------|------------------|
| Windows          | vagrant          | vagrant          | 1          | {your_default_network}.10  |
| Debian Dualboot  | user / root      | userpass / rootpass | 1       | {your_default_network}.10 |
| OMV (nested)     | root / admin     | 1647 / sanbox    | 2          | {your_default_network}.10 :8080  |

**Virt Level 1** = regular VM — **Virt Level 2** = nested (OMV inside Debian/Windows)

---

## Results

  - As a result of these steps, a dual-boot structure was achieved within a single virtual machine. After typing the vagrant up command, all steps were performed sequentially. After the Vagrant Windows virtual machine was powered on, it was managed with Ansible in a new virtual machine created in the sidecar structure, and automated operations were performed. As a result, access to the OMV interface via the {your_default_ip}.10:8080 connection was successfully established. The Windows machine was then shut down, and the process for automatically installing Debian on the second disk was initiated. These processes involved accessing the prepared file provided by the host machine, and Debian was successfully installed on the new virtual machine. Grub was also successfully installed along with the installation. The installation was successfully confirmed, and the necessary operations were automatically performed with Ansible on the Debian virtual machine. The Linux machine was then shut down, and the temporary virtual machine definition created was deleted. Now we have a virtual machine with a dual-boot operating system, and no matter which operating system we select, it automatically accesses the OMV disk, starts a virtual machine with that disk, and we can successfully access the virtual machine.

  - As a result of all these steps, our lab environment was automatically launched. Tests show that this environment was ready in approximately one hour. Regardless of the operating system selected, access to the commonly used exFAT-formatted OMV disks was seamless on all systems, and each time the virtual machine was restarted, the OMV virtual machine was automatically started within the virtual environment; access tests were completed successfully on both operating systems.

### OMV Disk and Repo
- [OMV Disk Download](https://drive.google.com/file/d/1Xf_O8pprBlkvgMcjBodDnoYdFOh6JFC9/view?usp=sharing)
    - `disk.vmdk SHA256`: 7f47710747af62be50a926959e430eef17386d3c9b9d600bbec513de74c329ed
    - `disk.vmdk SHA512`: 6b8d45fc3a24f85a5ed132e231fd24e6ed36c3ab75260fda98bc5ab5a190cc321f0db73d7d5114ff6e8c0b7ac612ea8389474b3c447ce1b5588bcdaf7a9c569f
- [GitHub Repo](https://github.com/ReqwerT/labfortasks/tree/main)
- [Error Table](https://github.com/ReqwerT/labfortasks/blob/main/errors.md)

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
