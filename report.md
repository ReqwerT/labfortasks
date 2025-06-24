# Purpose and Requirements

Our purpose in designing the system is to create a lab environment that will be used in future tasks and that is automatically started up. The reason why we did not try the tasks on baremetal is that our system may be damaged while performing some dangerous operations. Therefore, it would be best to run it in a virtual environment in terms of both our time and system security. However, running the lab environment may still cause us trouble. Therefore, I designed the entire lab environment that we created using ansible and scripts to be started up with just one command.

We need some requirements to get the system up and running. I created the test environment on bare metal debian. Vagrant, libvirt and vagrant-libvirt plugins must be installed on bare metal. The “start_all.sh” script in the main directory I created checks the requirements in order and automatically installs them if there is anything missing. You can also perform the necessary installations manually. The stages will be available on github. I entered the config settings for two virtual machines in a single Vagrantfile. Since our Windows machine will be nested-virt, I allocated 16GB RAM and 4 CPU cores. Since my Ubuntu machine will work entirely for ansible management, I kept its features minimal. I assigned static IP addresses to both virtual machines (libvirt_winvm and libvirt_ubuntu). I will present all the configs to you in the following lines of the report. You can change the features from the relevant places according to your own needs.

Another requirement for the system is that I could not give a static IP address to my dualboot debian virtual machine that I automatically set up with the preseed file I wrote. It preferred to assign this IP address with DHCP every time, and because of this problem, I could not manage my dual-boot debian virtual machine that I set up with my ansible machine and I could not load the requirements to that virtual machine and start it. Therefore, I wrote the management settings directly for the host machine with ansible. In our “/libvirt/scriptsdeb/hosts.ini” file, you need to fill in the authorization information from the part written as “[baremetal:vars]”. Thanks to this information, our ansible machine will be able to communicate with the host machine without any problems and complete the necessary automation without any problems. I will explain the system’s yml playbooks and all the work they do in the next section completely and clearly.

# Operating the System and Its Functioning

To run the system, we first need to download the files from github. Then our “libvirt/start_all.sh” script will start the entire system.

- Let's access the "/libvirt" folder with the terminal and type "./start_all.sh" into the terminal. This command will run our start_all.sh script and perform all the steps automatically.

### What does this script do?

- Checks the requirements in the system (vagrant, libvirt, vagrant-libvirt plugin). If these software are not available, it automatically performs an installation.
- It sets the internet interface we use in the system. All machines in the system communicate over the 192.168.121.0/24 network. If this interface does not exist, it creates it.
- After the requirements checks, it enters the necessary commands to run our virtual machines. It first runs our Windows virtual machine with the "vagrant up winvm" command. Once this process is complete, it runs our Ubuntu machine with the "vagrant up ubuntu –provider=libvirt" command.
- While running our Windows machine:
  - Assigns static IP: 192.168.121.130
  - Pulls ConfigurationRemotingForAnsible.ps1 script from GitHub
  - Runs /libvirt/scriptswin/install_qemu.ps1 via rsync
  - Enables Windows features: Microsoft Hyper-V, Hypervisor Platform, Virtual Machine Platform, WSL
  - Runs /images/download.ps1 to:
    - Install Python
    - Install pip and gdown
    - Download disk.vmdk
    - Create disk1.vmdk using qemu-img

- Ubuntu virtual machine gets static IP: 192.168.121.20 and runs /libvirt/scriptsdeb/req.sh to:
  - Update packages, install ansible and winrm
  - Apply the following playbooks in order:
    - shrinkdisk.yml
    - copy_disks.yml
    - start_vm.yml
    - close_windows.yml
    - run_preseed.yml
    - run.yml
    - install_qemu.yml
    - start_vm_when_reboot_debian.yml
    - change_vda.yml
    - delete_enp1s0.yml
    - enable_dualboot_on_baremetal.yml

# IP Table and Credentials

| Machine          | Username        | Password      | Virt Level | IP Address       |
|------------------|------------------|---------------|------------|------------------|
| Windows          | vagrant          | vagrant       | 1          | 192.168.121.130  |
| Debian Dualboot  | user/root        | userpass/rootpass | 1          | 192.168.121.145  |
| Ubuntu Ansible   | vagrant          | vagrant       | 1          | 192.168.121.20   |
| OMV (nested)     | root/admin       | 1647/sanbox   | 2          | Virtual Host IP  |
| Baremetal Host   | root             | 1647          | -          | 192.168.121.1    |

# Notes

- Virt Level 1 = first-level VM
- Virt Level 2 = nested VM (OMV inside Debian/Windows)

# Resources

- [OMV Disk Download](#)
- [GitHub Repo](#)

# Results

As a result of the operations:
- Two virtual machines were started using Vagrant automatically
- Windows was provisioned and made Ansible-ready
- Ubuntu was started and acted as controller
- Debian installation via Preseed was completed automatically on dualboot image
- Static IP was assigned to Debian via expect script and console access
- QEMU was installed and VM boot service created on Debian
- OMV disks (disk.vmdk and disk1.vmdk) were mounted
- On every reboot, OMV starts as nested VM inside the chosen OS

# System Specs

- Model: Asus fx706li-hx199
- CPU: Intel Core i5 10300h
- RAM: 32GB DDR4
- Disk: 480GB M.2 SSD
- OS: Baremetal Debian
- VT-x: Enabled
