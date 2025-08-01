#!/bin/bash
set -euo pipefail

VM_NAME="libvirt_winvm"
TMP_XML="/tmp/${VM_NAME}.xml"

# --- Determine libvirt URI and pool directory ---
uri=$(virsh uri 2>/dev/null || true)
if [[ "$uri" == *session* ]]; then
  echo ">>> Session mode detected (uri=$uri)"
  POOL_DIR="$HOME/.local/share/libvirt/images"
else
  echo ">>> System mode detected (uri=$uri)"
  POOL_DIR="/var/lib/libvirt/images"
fi

# --- Disk paths based on mode ---
DISK1="$POOL_DIR/lastden.qcow2"
DISK2="$POOL_DIR/libvirt_winvm.img"

echo ">>> Using disk paths:"
echo "    Disk1 = $DISK1"
echo "    Disk2 = $DISK2"

# Dump current domain XML
virsh dumpxml "$VM_NAME" > "$TMP_XML"

# Remove existing <boot> elements under <os>
xmlstarlet ed -L -d "/domain/os/boot" "$TMP_XML" || true

# Enable bootmenu
xmlstarlet ed -L -u "/domain/os/bootmenu/@enable" -v "yes" "$TMP_XML" \
  || xmlstarlet ed -L -s "/domain/os" -t elem -n bootmenu -v "" \
                   -i "/domain/os/bootmenu" -t attr -n enable -v "yes" "$TMP_XML"

# Remove any old disk-level <boot> entries
xmlstarlet ed -L -d "//disk/boot" "$TMP_XML"

# Add new boot order for first disk
xmlstarlet ed -L \
  -s "//disk[source[@file='${DISK1}']]" -t elem -n boot -v "" \
  -i "//disk[source[@file='${DISK1}']]/boot" -t attr -n order -v "1" \
  "$TMP_XML"

# Add new boot order for second disk
xmlstarlet ed -L \
  -s "//disk[source[@file='${DISK2}']]" -t elem -n boot -v "" \
  -i "//disk[source[@file='${DISK2}']]/boot" -t attr -n order -v "2" \
  "$TMP_XML"

# Redefine the domain
virsh define "$TMP_XML"

echo ">>> Operation successful. New boot order devices:"
virsh dumpxml "$VM_NAME" | grep -A 5 '<disk' | grep 'boot\|source'

# Cleanup temporary XML
rm -f "$TMP_XML"
