# OTOMATİK LAB ORTAMI (VAGRANT + ANSIBLE)

## Amaç

Vagrant ile kurduğum sanal makinelerin içine Ansible kullanarak;

- Otomatik şekilde dualboot yapılandırılmış bir sistem oluşturdum,
- Hangi işletim sistemi açılırsa açılsın, OMV sanal makinesine ortak diskler üzerinden otomatik erişim sağladım ve her açılışta OMV VM’nin otomatik başlamasını sağladım.

## Yaptığım İşlemler

- Windows makineme QEMU’nun son sürümünü yükledim, sanallaştırma teknolojilerini etkinleştirdim.
- OMV için fiziksel diskimi 20 GB küçülttüm.
- Bu diski `exFAT` formatında biçimlendirerek Linux, macOS ve Windows'tan erişilebilir hale getirdim.
- OMV image dosyasını bu diske kopyaladım, ayrıca 10 GB ekstra `.vmdk` disk oluşturdum.
- Windows açıldığında OMV VM’yi otomatik başlatan `.ps1` ve `.bat` dosyalarını ilgili klasörlere otomatik yerleştirdim.
- `Vagrantfile` içine dualboot Debian kurulumu için 25 GB’lık `lastden.qcow2` diskini ekledim.
- Bu diske preseed kullanarak Debian’ı tam otomatik kurdum ve statik IP atayarak Ansible erişimini sağladım.
- Debian içine Ansible ile QEMU yükledim, OMV diskini mount ettim ve Debian her açıldığında OMV VM’nin otomatik başlaması için systemd servisi tanımladım.

## Gereksinimler

Bu sistemin çalışması için yalnızca şu 3 uygulama yeterli:

- Vagrant 2.4.7
- libvirt 9.0.0
- Ansible 2.4.18

> **Not:** Tüm süreci bare-metal Debian 12 sistem üzerinde gerçekleştirdim.

## Sidecar Notu

İlk başta sidecar Ansible sanal makinesi kullanmayı denedim ama fazladan karmaşa yarattığı ve zaman zaman sistemi kilitlediği için doğrudan ana makine üzerinden Ansible ile devam ettim. İstenirse sidecar yapısını da tekrar entegre edebilirim.

## Sistemi Başlatma

```bash
# 1. Projeyi klonladım
git clone <repo-link>
cd labfortasks/libvirt/

# 2. Başlatma scriptine çalıştırma izni verdim
chmod +x start_all.sh

# 3. ROOT olarak çalıştırıyorum
sudo ./start_all.sh
```

Bu script sırasıyla şu işlemleri yapıyor:

- Gereksinim kontrolü yapıyor, eksikse kuruyor.
- Sanal makineleri başlatıyor.
- Ansible playbook’larını çalıştırıyor.

## Sistem İşleyişi

### 1. Gereksinim Kontrolü

Eksik program varsa script bunları otomatik olarak yüklüyor.

### 2. `winvm` Sanal Makinesini Başlatıyorum

- Statik IP: `192.168.121.130`
- `Vagrantfile` içindeki özel shell scriptler tetikleniyor:
  - `/images` ve `/libvirt/scriptswin` klasörlerini paylaşıyorum.
  - `ConfigureRemotingForAnsible.ps1` dosyasını uzaktan yüklüyorum.
  - `install_qemu.ps1` ile:
    - QEMU kuruluyor.
    - Hyper-V, WSL, Sanallaştırma açılıyor.
  - `download.ps1` ile OMV `.vmdk` dosyası indiriliyor.
  - Ek olarak 10 GB `.vmdk` disk oluşturuluyor.
  - Windows VM’e 16 GB RAM ve 4 CPU çekirdeği atadım.
  - `lastden.qcow2` diskini Debian kurulumu için ekledim.

### 3. Ansible ile Windows Tarafını Otomatikleştiriyorum

- `shrink_disk.yml`: 20 GB disk shrink edilip `D:` olarak `exFAT` biçiminde formatlanıyor.
- `copy_disks.yml`: OMV disklerini `D:` sürücüsüne kopyalıyorum.
- `start_vm.yml`:
  - QEMU `.ps1` config dosyasını `C:/vagrant_vm_boot` klasörüne kaydettim.
  - Bu scripti çalıştıran `.bat` dosyasını `Startup` klasörüne ekledim.
  - OMV’ye 192.168.121.130:8080 üzerinden erişilebiliyor.
- `close_windows.yml`: Windows VM’yi kapatıyorum.
- Ardından 30 saniye bekliyorum.

### 4. Debian’ı Preseed ile Otomatik Kuruyorum

- Yeni terminalde `/preseed/auto_debian_install.sh` çalıştırılıyor.
  - `preseed.cfg` HTTP ile 8000 portunda sunuluyor.
  - `virsh` komutları ile VM kuruluyor.
  - `extra-args` üzerinden statik IP veriliyor.
- GRUB’un diğer işletim sistemlerini tanıması için `only_boot_debian=false` kullandım.
- Debian kurulumu yaklaşık 30 dakika sürüyor.
- Kurulum sonrası:
  - Windows diski `vdb`, OMV diski `vdb2` olarak görülüyor.
  - `/etc/fstab` içine mount girdisini ekledim.

### 5. Debian İçinde Otomasyonu Tamamlıyorum

- SSH erişimi açıldığında, debian kurulumun başarılı biçimde bittiğini anlıyorum ve script sırasıyla şu işlemleri yapıyor:
  - `install_qemu_on_debian.yml` ile QEMU kuruluyor.
  - `start_vm_when_reboot_debian.yml` ile systemd servisi kuruluyor.
  - `change_vda.yml` ile disk yolu `vdb2` yerine `vda2` olacak şekilde fstab güncelleniyor.
  - `shutdown_lin.yml` ile Debian VM’yi kapatıyorum.

### 6. Son Adım: Geçici VM’yi Kaldırmak

- `virsh undefine debian-in-windows` komutuyla debian kurmak için tanımlanan geçici VM tanımını siliyoruz.

## Sonuç

Artık elimizde dualboot çalışan bir sanal makine var:

- İster Windows ister Debian açayım,
- OMV sanal makinesi her iki sistemde de otomatik başlıyor,
- Windows için, Ağdaki başka bir cihazdan `http://192.168.121.130:8080` adresine girerek OMV’ye erişebiliyorum.
- Debian için, Ağdaki başka bir cihazdan `http://192.168.121.145:8080` adresine girerek OMV’ye erişebiliyorum.
