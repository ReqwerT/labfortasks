
# REPORT

## Task 1

### Automated System Development Using Vagrant-Ansible

**Prepared by: Seyfullah Kaya**

---

## Purpose and Requirements

Our purpose in designing the system is to create a lab environment that will be used in future tasks and that is automatically started up. The reason why we did not try the tasks on baremetal is that our system may be damaged while performing some dangerous operations. Therefore, it would be best to run it in a virtual environment in terms of both our time and system security. However, running the lab environment may still cause us trouble. Therefore, I designed the entire lab environment that we created using ansible and scripts to be started up with just one command.

We need some requirements to get the system up and running. I created the test environment on bare metal debian. Vagrant, libvirt and vagrant-libvirt plugins must be installed on bare metal. The "start_all.sh" script in the main directory I created checks the requirements in order and automatically installs them if there is anything missing. You can also perform the necessary installations manually. The stages will be available on github. I entered the config settings for two virtual machines in a single Vagrantfile. Since our Windows machine will be nested-virt, I allocated 16GB RAM and 4 CPU cores. Since my Ubuntu machine will work entirely for ansible management, I kept its features minimal. I assigned static IP addresses to both virtual machines (libvirt_winvm and libvirt_ubuntu). I will present all the configs to you in the following lines of the report. You can change the features from the relevant places according to your own needs.

Another requirement for the system is that I could not give a static IP address to my dualboot debian virtual machine that I automatically set up with the preseed file I wrote. It preferred to assign this IP address with DHCP every time, and because of this problem, I could not manage my dual-boot debian virtual machine that I set up with my ansible machine and I could not load the requirements to that virtual machine and start it. Therefore, I wrote the management settings directly for the host machine with ansible. In our "/libvirt/scriptsdeb/hosts.ini" file, you need to fill in the authorization information from the part written as "[baremetal:vars]". Thanks to this information, our ansible machine will be able to communicate with the host machine without any problems and complete the necessary automation without any problems. I will explain the system’s yml playbooks and all the work they do in the next section completely and clearly.

---

## Operating the System and Its Functioning

To run the system, we first need to download the files from github. Then our "libvirt/start_all.sh" script will start the entire system.

```bash
cd /libvirt
./start_all.sh
```

This script:
- Checks vagrant, libvirt, and vagrant-libvirt plugin; installs if missing
- Ensures 192.168.121.0/24 network exists
- Starts Windows VM, runs provisioning:
  - Static IP 192.168.121.130
  - Pulls ConfigurationRemotingForAnsible.ps1
  - Runs install_qemu.ps1 (enables Hyper-V, installs QEMU)
  - Runs download.ps1 (installs Python, gdown, downloads disk.vmdk, creates disk1.vmdk)
- Starts Ubuntu Ansible VM:
  - Static IP 192.168.121.20
  - Runs req.sh which executes the following playbooks:

### Ansible Playbooks

- `shrinkdisk.yml`: Shrinks 20GB space from Windows disk, formats as exFAT `D:` for OMV use.
- `copy_disks.yml`: Copies OMV disks (disk.vmdk, disk1.vmdk) to `D:` drive.
- `start_vm.yml`: Creates QEMU boot scripts for OMV, enables startup with Windows using WHPX accel, 4GB RAM, 2 disks, and port forwarding.
- `close_windows.yml`: Shuts down Windows VM to release resources.
- `run_preseed.yml`: Runs `auto_debian_install.sh` on host, starts new VM with debian.qcow2 as vda, installs Debian via preseed HTTP.
- `run.yml`: Connects via `virsh console`, sets static IP 192.168.121.145 using expect script.
- `install_qemu.yml`: Installs QEMU in Debian virtual machine.
- `start_vm_when_reboot_debian.yml`: Configures OMV disk in `/etc/fstab`, sets up `qemu-vm.service` for nested VM autostart on every reboot (ports 8080, 8443, 2222).
- `change_vda.yml`: Fixes `/etc/fstab` to use `vda` instead of `vdb` for proper boot.
- `delete_enp1s0.yml`: Deletes old static IPs, assigns 192.168.121.145 to `enp8s0`, and shuts down Debian VM.
- `enable_dualboot_on_baremetal.yml`: Sets 2nd disk as bootable, enables VM boot menu (Debian or Windows), redefines VM config.

---

## System Access Table

| Machine          | Username        | Password         | Virt Level | IP Address       |
|------------------|------------------|------------------|------------|------------------|
| Windows          | vagrant          | vagrant          | 1          | 192.168.121.130  |
| Debian Dualboot  | user / root      | userpass / rootpass | 1       | 192.168.121.145  |
| Ubuntu Ansible   | vagrant          | vagrant          | 1          | 192.168.121.20   |
| OMV (nested)     | root / admin     | 1647 / sanbox    | 2          | Host VM's IP     |
| Baremetal Host   | root             | 1647             | -          | 192.168.121.1    |

**Virt Level 1** = regular VM — **Virt Level 2** = nested (OMV inside Debian/Windows)

---

## Results

- Full system booted with one script
- Windows and Ubuntu VMs provisioned automatically
- Preseed Debian installed via host automation
- Static IP and Ansible communication fully functional
- OMV runs automatically inside Debian/Windows with shared disks

### OMV Disk and Repo
- [OMV Disk Download](#)
- [GitHub Repo](#)

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
