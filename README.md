# Automatic Lab Environment Setup (Vagrant + Ansible + Libvirt)

This project sets up a fully automated virtualized lab environment using Vagrant, Libvirt and Ansible. It is aimed at automatic setup of OpenMediaVault (OMV) virtual machines on Windows and Debian systems.

## Requirements

Before installing the system, the following components must be installed and configured:

1. `vagrant`
2. `libvirt`
3. `vagrant-libvirt` plugin
4. Baremetal access information:

Enter your access information in the `[baremetal:vars]` section in the `/libvirt/scriptsdeb/hosts.ini` file.
5. SSH must be installed on the baremetal system, and root login must be enabled via the `sshd_config` file.

## Path Settings (Must Be Done)

You must add the full paths given below to the relevant lines of the following files:

- `/scriptsdeb/run_preseed.yml` → line **10**

to the `path:` line;
`/libvirt/preseed/auto_debian_install.sh` full path

- `/scriptsdeb/run_preseed.yml` → line **22**
In `chdir:` line:
Full path to `/libvirt/preseed/` folder

- `/scriptsdeb/run.yml` → line **7**
In `command:` line:
Full path to `/libvirt/static_ip/set_ip_console.sh` file

- `/preseed/auto_debian_install.sh` → line **10**
In `PRESEED_DIR=` line:
You must enter the full path to `/libvirt/preseed/` folder.

## Starting the System

You can start the system by following the steps below via the terminal:

```bash
cd libvirt
./start_all.sh
```
This command automatically installs and runs the entire lab environment. You can review the [report.md](https://github.com/ReqwerT/labfortasks/blob/main/report.md) file for the entire technical process, installation chain and architectural details of the system.
