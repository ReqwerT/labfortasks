#!/bin/bash

VM_NAME="preseed-in-windows"

# VM'nin durumunu kontrol et
state=$(virsh domstate "$VM_NAME" 2>/dev/null)

if [[ "$state" == "running" ]]; then
  echo "VM çalışıyor. Önce temiz kapatma denenecek..."
  virsh shutdown "$VM_NAME" || true

  # 15 saniye bekle temiz kapanma için
  for i in {1..15}; do
    state=$(virsh domstate "$VM_NAME" 2>/dev/null)
    if [[ "$state" == "shut off" ]]; then
      echo "VM temiz kapandı."
      break
    fi
    sleep 1
  done

  # Eğer hala çalışıyorsa zorla kapat
  state=$(virsh domstate "$VM_NAME" 2>/dev/null)
  if [[ "$state" != "shut off" ]]; then
    echo "VM temiz kapatılmadı, zorla kapatılıyor..."
    virsh destroy "$VM_NAME" || true
    sleep 3
  fi
else
  echo "VM durumu: $state. Kapatmaya gerek yok."
fi

# VM tanımını kaldır
echo "VM tanımı kaldırılıyor..."
virsh undefine "$VM_NAME" --nvram || true

echo "İşlem tamamlandı."
