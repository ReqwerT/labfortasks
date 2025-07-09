# OTOMATİK LAB ORTAMI (VAGRANT + ANSIBLE)

## Amaç

Vagrant ile kurulan sanal makinelerin içine Ansible kullanarak;

- Otomatik şekilde dualboot yapılandırılmış bir sistem kurulması,
- Hangi işletim sistemi açılırsa açılsın, OMV sanal makinesine ortak diskler üzerinden otomatik erişim sağlanması ve her açılışta OMV VM’nin otomatik başlaması hedeflenmiştir.

## Tamamlanan İşlemler

- Windows makinesine QEMU son sürümü yüklendi, sanallaştırma teknolojileri aktif edildi.
- OMV için 20 GB fiziksel disk shrink edildi.
- Bu disk `exFAT` formatında biçimlendirildi (Linux, macOS, Windows tarafından erişilebilir).
- OMV image dosyası bu diske kopyalandı, yanında 10 GB ekstra `.vmdk` disk oluşturuldu.
- Windows açıldığında OMV VM’yi otomatik başlatan `.ps1` ve `.bat` dosyaları otomatik olarak ilgili klasörlere yerleştirildi.
- `Vagrantfile` içerisine `dualboot Debian` kurulumu için ekstra 25 GB `.qcow2` disk eklendi (`lastden.qcow2`).
- Bu diske preseed ile tam otomatik Debian kurulumu yapıldı ve Ansible için statik IP atandı.
- Debian içinden Ansible ile QEMU kuruldu, OMV diski mount edilerek OMV VM sistem servisi haline getirildi.

## Gereksinimler

Sistemi kullanmak için yalnızca 3 programa ihtiyacınız var:

- Vagrant 2.4.7
- libvirt 9.0.0
- Ansible 2.4.18

> **Not:** Baremetal olarak Debian 12 kullanılmıştır.

## Sidecar Notu

İlk olarak sidecar Ansible sanal makinesi düşünülmüştü ancak karmaşıklık ve kilitlenmeler nedeniyle bu yöntem bırakılmış, doğrudan ana makinadan Ansible yönetimi tercih edilmiştir. İstenirse tekrar sidecar yapılandırması yapılabilir.

## Sistemi Başlatma

```bash
# 1. Projeyi klonlayın
git clone <repo-link>
cd labfortasks/libvirt/

# 2. Başlatma scriptine çalıştırma izni verin
chmod +x start_all.sh

# 3. ROOT olarak çalıştırın
sudo ./start_all.sh
```

Bu script tüm işlemleri sırayla gerçekleştirir:

- Gereksinimleri kontrol eder, eksik uygulamaları yükler.
- VM’leri başlatır.
- Ansible playbook'larını otomatik çalıştırır.

## Sistem İşleyişi

### 1. Gereksinim Kontrolü

Bilgisayardaki eksik programlar kontrol edilir ve eksikse otomatik olarak yüklenir.

### 2. `winvm` Sanal Makinesi Başlatılır

- Statik IP: `192.168.121.130`
- `Vagrantfile` içerisindeki özel shell scriptler çalışır:
  - `/images` ve `/libvirt/scriptswin` klasörleri paylaşılır.
  - `ConfigureRemotingForAnsible.ps1` uzaktan yüklenir.
  - `install_qemu.ps1` çalıştırılarak:
    - QEMU yüklenir.
    - Hyper-V, Sanallaştırma ve WSL özellikleri etkinleştirilir.
  - `download.ps1` ile internetten OMV `.vmdk` dosyası indirilir.
  - 10 GB’lık ikinci `.vmdk` disk oluşturulur.
  - Windows VM'e 16 GB RAM ve 4 CPU çekirdeği atanır.
  - `lastden.qcow2` diski Debian kurulumu için eklenmiştir.

### 3. Ansible ile Windows Otomasyonu

- `shrink_disk.yml`: 20 GB’lık disk shrink edilir, `D:` olarak `exFAT` formatında biçimlendirilir.
- `copy_disks.yml`: OMV `.vmdk` dosyası ve ek disk `D:` sürücüsüne kopyalanır.
- `start_vm.yml`:
  - QEMU için `.ps1` uzantılı config dosyası `C:/vagrant_vm_boot` klasörüne yerleştirilir.
  - Bu scripti çalıştıran `.bat` dosyası `Startup` klasörüne eklenir.
  - Port yönlendirme yapılır, OMV’ye 192.168.121.130:8080 adresinden erişim sağlanır.
- `close_windows.yml`: Windows sanal makinesi kapatılır.
- 30 saniyelik bekleme uygulanır.

### 4. Preseed ile Debian Kurulumu

- Yeni bir terminalde `/preseed/auto_debian_install.sh` çalıştırılır:
  - `8000` portu üzerinden `preseed.cfg` HTTP ile sunulur.
  - `virsh` komutları ile yeni VM başlatılır.
  - `extra-args` içine static IP tanımı yapılır.
- `preseed.cfg` dosyasındaki `only_boot_debian=false` ayarı sayesinde GRUB diğer işletim sistemlerini de tanır.
- Yaklaşık 30 dakikalık yükleme süresinden sonra:
  - Windows diski Debian tarafından 2. disk olarak tanınır (`vdb`).
  - OMV diski `vdb2` olarak `/etc/fstab` içerisine eklenir.

### 5. Ansible ile Debian Otomasyonu

- SSH bağlantısı kurulabilir hale geldiğinde Ansible erişimi başlar:
  - `install_qemu_on_debian.yml`: Debian VM’e QEMU yüklenir.
  - `start_vm_when_reboot_debian.yml`: OMV sanal makinesi için sistem servisi oluşturulur.
  - `change_vda.yml`: Debian içinde `vdb2`, ana Vagrant sanal makinesinde `vda2` olduğundan `/etc/fstab` düzenlenir.
  - `shutdown_lin.yml`: Debian VM kapatılır.

### 6. Son Temizlik

- `virsh undefine debian-in-windows` komutu ile geçici Debian VM tanımdan kaldırılır.

## Sonuç

Artık elinizde dualboot bir sanal makine mevcut:

- İster Windows açın, ister Debian.
- Her iki sistemde de OMV sanal makinesi ortak disklerden erişilerek otomatik çalışır.
- OMV’ye aynı ağdan yalnızca `http://192.168.121.130:8080` adresiyle tarayıcıdan ulaşmanız yeterlidir.
