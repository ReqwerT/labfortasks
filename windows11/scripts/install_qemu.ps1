# QEMU kurulumu ve sanallaştırma özelliklerini etkinleştirme

# 1. Kurulum bilgileri
$qemuInstallerUrl = "https://qemu.weilnetz.de/w64/2025/qemu-w64-setup-20250210.exe"
$downloadPath = "$env:USERPROFILE\Downloads\qemu_installer.exe"
$qemuInstallDir = "C:\Program Files\qemu"

# 2. QEMU zaten kurulu değilse indir ve kur
if (-Not (Test-Path $qemuInstallDir)) {
    Write-Host "[INFO] QEMU kurulumu başlatılıyor..."
    Invoke-WebRequest -Uri $qemuInstallerUrl -OutFile $downloadPath
    Start-Process -FilePath $downloadPath -ArgumentList "/S" -Wait
} else {
    Write-Host "[INFO] QEMU zaten kurulu. Kurulum atlandı."
}

# 3. QEMU klasörü sistem PATH'e ekli mi kontrol et, yoksa ekle
$machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if (-Not ($machinePath -like "*$qemuInstallDir*")) {
    Write-Host "[INFO] QEMU klasörü sistem PATH'e ekleniyor..."
    [Environment]::SetEnvironmentVariable("Path", "$machinePath;$qemuInstallDir", [EnvironmentVariableTarget]::Machine)
} else {
    Write-Host "[INFO] QEMU klasörü zaten sistem PATH içinde."
}

# 4. Gerekli Windows özelliklerini etkinleştir
$features = @(
    "Microsoft-Hyper-V-All",
    "HypervisorPlatform",
    "VirtualMachinePlatform",
    "Microsoft-Windows-Subsystem-Linux"
)

foreach ($feature in $features) {
    Write-Host "[INFO] Özellik etkinleştiriliyor: $feature"
    Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -All | Out-Null
}

Write-Host "`n[✓] Kurulum ve yapılandırma tamamlandı."
Write-Host "[ℹ] Lütfen değişikliklerin etkinleşmesi için bilgisayarınızı yeniden başlatın."
