# install_python_gdown_and_download.ps1
# Installs Python + pip + gdown and downloads disk.vmdk from Google Drive
# Then creates disk1.vmdk (10G) in same folder using qemu-img

# === Config ===
$pythonUrl   = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-amd64.exe"
$installer   = "$env:TEMP\python-installer.exe"
$installDir  = "C:\Program Files\Python311"
$pythonExe   = "$installDir\python.exe"
$pipExe      = "$installDir\Scripts\pip.exe"
$fileId      = "1Xf_O8pprBlkvgMcjBodDnoYdFOh6JFC9"

# Full path of qemu-img.exe
$qemuImgPath = "C:\Program Files\qemu\qemu-img.exe"

# Current script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outFilePath1 = Join-Path $scriptPath "disk.vmdk"
$outFilePath2 = Join-Path $scriptPath "disk1.vmdk"

# === 1. Download Python installer ===
Write-Host "`n[*] Downloading Python installer..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $pythonUrl -OutFile $installer

# === 2. Install Python silently ===
Write-Host "[*] Installing Python to $installDir..." -ForegroundColor Cyan
Start-Process -FilePath $installer -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 TargetDir=`"$installDir`"" -Wait

# === 3. Remove installer ===
Remove-Item $installer -Force
Write-Host "[*] Installer removed." -ForegroundColor DarkGray

# === 4. Ensure pip is available ===
if (-not (Test-Path $pipExe)) {
    Write-Host "[!] pip not found, installing manually..." -ForegroundColor Yellow
    & "$pythonExe" -m ensurepip --upgrade
}

# === 5. Install gdown ===
if (Test-Path $pipExe) {
    Write-Host "`n[*] Installing gdown..." -ForegroundColor Cyan
    & "$pipExe" install --no-cache-dir gdown
} else {
    Write-Host "[X] pip still missing. Cannot continue." -ForegroundColor Red
    exit 1
}

# === 6. Download disk.vmdk from Google Drive ===
Write-Host "`n[*] Downloading disk.vmdk from Google Drive..." -ForegroundColor Cyan
& "$pythonExe" -m gdown "https://drive.google.com/uc?id=$fileId" -O "$outFilePath1"

# === 7. Create disk1.vmdk using qemu-img ===
Write-Host "`n[*] Creating disk1.vmdk (10G) using qemu-img..." -ForegroundColor Cyan
& "$qemuImgPath" create -f vmdk "$outFilePath2" 10G

# === Done ===
Write-Host "`n[✓] Download complete: $outFilePath1" -ForegroundColor Green
Write-Host "[✓] Created empty disk: $outFilePath2"
Write-Host "Python installed in: $installDir"
Write-Host "No reboot required. Ready to use."
