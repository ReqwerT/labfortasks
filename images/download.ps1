# Google Drive dosya ID'sini girin
$FileID = "1Xf_O8pprBlkvgMcjBodDnoYdFOh6JFC9"

# Google Drive indirme URL'si
$DownloadURL = "https://drive.google.com/uc?export=download&id=$FileID"

# Dosyanın kaydedileceği yol
$DestinationPath = ".\disk.vmdk"

# İndirilen dosyanın kaydedileceği yol
Write-Host "Downloading file from Google Drive..."
Invoke-WebRequest -Uri $DownloadURL -OutFile $DestinationPath

Write-Host "Download completed! The file has been saved to: $DestinationPath"

# 20GB'lık disk oluşturma
$NewDiskPath = ".\disk1.vmdk"
Write-Host "Creating 20GB VMDK disk at $NewDiskPath..."
qemu-img create -f vmdk $NewDiskPath 20G

Write-Host "Disk1.vmdk (20GB) created successfully at: $NewDiskPath"
