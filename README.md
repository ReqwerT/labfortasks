# Otomatik Lab Ortamı Kurulumu (Vagrant + Ansible + Libvirt)

Bu proje, Vagrant, Libvirt ve Ansible kullanarak tamamen otomatikleştirilmiş bir sanallaştırılmış laboratuvar ortamı kurar. Windows ve Debian sistemleri üzerinde OpenMediaVault (OMV) sanal makinelerinin otomatik kurulumu hedeflenmiştir.

## Gereksinimler

Sistemi kurmadan önce aşağıdaki bileşenlerin yüklü olması ve yapılandırılmış olması gerekir:

1. `vagrant`
2. `libvirt`
3. `vagrant-libvirt` plugin
4. Baremetal erişim bilgileri:  
   `/libvirt/scriptsdeb/hosts.ini` dosyasında `[baremetal:vars]` bölümüne erişim bilgilerinizi girin.

## Yol Ayarları (Mutlaka Yapılmalı)

Aşağıdaki dosyaların ilgili satırlarına aşağıda verilen tam yolları eklemelisiniz:

- `/scriptsdeb/run_preseed.yml` → satır **10**  
  `path:` satırına:  
  `/libvirt/preseed/auto_debian_install.sh`

- `/scriptsdeb/run_preseed.yml` → satır **22**  
  `chdir:` satırına:  
  `/libvirt/preseed/`

- `/scriptsdeb/ru.yml` → satır **7**  
  `command:` satırına:  
  `/libvirt/static_ip/set_ip_console.sh`

- `/preseed/auto_debian_install.sh` → satır **10**  
  `PRESEED_DIR=` satırına:  
  `/libvirt/preseed/`

## Sistemi Başlatma

Terminal üzerinden aşağıdaki adımları takip ederek sistemi başlatabilirsiniz:

```bash
cd libvirt
./start_all.sh
```

Bu komut, tüm lab ortamını otomatik olarak kurar ve çalıştırır. Sistemin tüm teknik süreci, kurulum zinciri ve mimari detayları için report dosyasını inceleyebilirsiniz.
