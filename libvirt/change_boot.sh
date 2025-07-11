#!/bin/bash
set -euo pipefail

VM_NAME="libvirt_winvm"
TMP_XML="/tmp/${VM_NAME}.xml"

virsh dumpxml "$VM_NAME" > "$TMP_XML"

xmlstarlet ed -L -d "/domain/os/boot" "$TMP_XML" || true

echo "Boot menu is being activated"
xmlstarlet ed -L -u "/domain/os/bootmenu/@enable" -v "yes" "$TMP_XML" || \
xmlstarlet ed -L -s "/domain/os" -t elem -n bootmenu -v "" \
                     -i "/domain/os/bootmenu" -t attr -n enable -v "yes" "$TMP_XML"


xmlstarlet ed -L -d "//disk/boot" "$TMP_XML"

xmlstarlet ed -L -s "//disk[source[@file='/var/lib/libvirt/images/lastden.qcow2']]" -t elem -n boot -v "" \
  -i "//disk[source[@file='/var/lib/libvirt/images/lastden.qcow2']]/boot" -t attr -n order -v "1" "$TMP_XML"

xmlstarlet ed -L -s "//disk[source[@file='/var/lib/libvirt/images/libvirt_winvm.img']]" -t elem -n boot -v "" \
-i "//disk[source[@file='/var/lib/libvirt/images/libvirt_winvm.img']]/boot" -t attr -n order -v "2" "$TMP_XML"

virsh define "$TMP_XML"

echo "Operation successful"
virsh dumpxml "$VM_NAME" | grep -A 10 '<devices>' | grep 'file\|boot'

rm -f "$TMP_XML"
