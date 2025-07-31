# QEMU installation and enabling virtualization features

# 1. Installation details
$qemuInstallerUrl = "https://qemu.weilnetz.de/w64/2025/qemu-w64-setup-20250210.exe"
$downloadPath = "$env:USERPROFILE\Downloads\qemu_installer.exe"
$qemuInstallDir = "C:\Program Files\qemu"

# 2. Download and install QEMU if not already installed
if (-Not (Test-Path $qemuInstallDir)) {
    Write-Host "[INFO] QEMU installation is starting..."
    Invoke-WebRequest -Uri $qemuInstallerUrl -OutFile $downloadPath
    Start-Process -FilePath $downloadPath -ArgumentList "/S" -Wait
} else {
    Write-Host "[INFO] QEMU is already installed. Skipping installation."
}

# 3. Check if QEMU folder is in system PATH; if not, add it
$machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if (-Not ($machinePath -like "*$qemuInstallDir*")) {
    Write-Host "[INFO] Adding QEMU folder to system PATH..."
    [Environment]::SetEnvironmentVariable("Path", "$machinePath;$qemuInstallDir", [EnvironmentVariableTarget]::Machine)
} else {
    Write-Host "[INFO] QEMU folder is already in system PATH."
}

# 4. Enable required Windows features
$features = @(
    "Microsoft-Hyper-V-All",
    "HypervisorPlatform",
    "VirtualMachinePlatform",
    "Microsoft-Windows-Subsystem-Linux"
)

foreach ($feature in $features) {
    Write-Host "[INFO] Enabling feature: $feature"
    Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -All | Out-Null
}

Write-Host "`n[✓] Installation and configuration completed."
Write-Host "[ℹ] Please restart your computer for the changes to take effect."
