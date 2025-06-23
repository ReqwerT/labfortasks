# === KULLANICI AYARLARI ===
$PHYSICAL_DRIVE = "\\.\PhysicalDrive0"  # DİKKAT: Doğru disk numarası!
$ISO_PATH = "C:\vagrant\debian-netinst.iso"
$PRESEED_DIR = "C:\vagrant"
$PRESEED_FILE = "preseed.cfg"
$PRESEED_PORT = 8000
$QEMU_PATH = "C:\Program Files\qemu"
$VM_RAM = 2048
$VM_VCPUS = 2
$DEBIAN_KERNEL = "install.amd/vmlinuz"
$DEBIAN_INITRD = "install.amd/initrd.gz"

# === PORT KONTROLÜ ===
$portInUse = Get-NetTCPConnection -LocalPort $PRESEED_PORT -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host ">>> Uyarı: Port $PRESEED_PORT dolu, 8080'e geçiliyor."
    $PRESEED_PORT = 8080
}

# === LOCAL IP AL ===
$localIP = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notlike "Loopback*" -and $_.IPAddress -notlike "169.*" } |
    Select-Object -First 1).IPAddress

# === PRESEED HTTP SERVER AÇ ===
Write-Host ">>> Preseed dosyası HTTP sunucusunu başlatıyor (port $PRESEED_PORT)..."
Set-Location $PRESEED_DIR
$pythonProc = Start-Process python3 -ArgumentList "-m http.server $PRESEED_PORT" -PassThru
Start-Sleep -Seconds 3

# === PRESEED ERİŞİM TESTİ ===
$response = Invoke-WebRequest -Uri "http://$localIP`:$PRESEED_PORT/$PRESEED_FILE" -Method Head -ErrorAction SilentlyContinue
if (-not $response -or $response.StatusCode -ne 200) {
    Write-Host ">>> Hata: Preseed dosyasına erişilemiyor!"
    Stop-Process -Id $pythonProc.Id
    exit 1
}
Write-Host ">>> Preseed dosyasına erişim başarılı."

# === QEMU BAŞLAT ===
Write-Host ">>> QEMU ile Debian kurulumu başlatılıyor (fiziksel disk)..."
& "$QEMU_PATH\qemu-system-x86_64.exe" `
-drive file=$PHYSICAL_DRIVE,format=raw,if=virtio `
-m $VM_RAM `
-smp $VM_VCPUS `
-cdrom $ISO_PATH `
-boot d `
-net nic -net user `
-display sdl `
-kernel $DEBIAN_KERNEL `
-initrd $DEBIAN_INITRD `
-append "auto=true priority=critical url=http://$localIP`:$PRESEED_PORT/$PRESEED_FILE interface=auto console=ttyS0,115200n8 serial"

if ($LASTEXITCODE -ne 0) {
    Write-Host ">>> QEMU çalıştırma başarısız!"
    Stop-Process -Id $pythonProc.Id
    exit 1
}

# === HTTP SERVER'I KAPAT ===
Write-Host ">>> Kurulum bitti, HTTP sunucusu kapatılıyor."
Stop-Process -Id $pythonProc.Id
