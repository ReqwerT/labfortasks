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
