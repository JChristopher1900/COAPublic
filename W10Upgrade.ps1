<#
.SYNOPSIS
   Upgrades any edition of Windows 10 to Windows 10 version 22H2.
.DESCRIPTION
   This script downloads the Windows 10 22H2 ISO using Fido, mounts it, copies the setup files, and initiates the upgrade process.
.NOTES
   - Ensure that Fido.ps1 is available in the same directory as this script.
   - Run this script with administrative privileges.
#>
# Function to check if script is running as Administrator
function Ensure-Administrator {
   if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
       Write-Error "This script must be run as an Administrator."
       exit 1
   }
}
# Function to create directory if it doesn't exist
function Create-DirectoryIfNotExists {
   param (
       [string]$Path
   )
   if (-not (Test-Path -Path $Path)) {
       try {
           New-Item -ItemType Directory -Path $Path -Force | Out-Null
           Write-Output "Created directory: $Path"
       }
       catch {
           Write-Error "Failed to create directory $Path. $_"
           exit 1
       }
   }
   else {
       Write-Output "Directory already exists: $Path"
   }
}
# Function to download the Windows ISO
function Download-WindowsISO {
   param (
       [string]$FidoScriptPath,
       [string]$WinEdition,
       [string]$Release,
       [string]$Architecture,
       [string]$Language,
       [string]$DestinationPath
   )
   try {
       # Get download URL using Fido
       Write-Output "Retrieving download URL using Fido..."
       $URI = & $FidoScriptPath -Win 10 -Rel $Release -Arch $Architecture -Ed $WinEdition -Lang $Language -GetUrl
       if (-not $URI) {
           Write-Error "Failed to retrieve download URL."
           exit 1
       }
       Write-Output "Download URL obtained: $URI"
       # Start BITS transfer
       Write-Output "Starting download of Windows 10 $Release ISO..."
       $bitsJob = Start-BitsTransfer -Source $URI -Destination $DestinationPath -Asynchronous -Priority Foreground
       # Monitor the BITS job
       while (($bitsJob | Get-BitsTransfer).JobState -ne "Transferred") {
           $progress = [math]::Round( ($bitsJob.BytesTransferred / $bitsJob.BytesTotal) * 100, 2 )
           Write-Output "Downloading... Progress: $progress%"
           Start-Sleep -Seconds 10
       }
       # Complete the transfer
       Complete-BitsTransfer -BitsJob $bitsJob
       Write-Output "Download completed successfully."
   }
   catch {
       Write-Error "Error during download: $_"
       # Cleanup partial download
       if (Test-Path -Path $DestinationPath) {
           Remove-Item -Path $DestinationPath -Force
           Write-Output "Partial download removed: $DestinationPath"
       }
       exit 1
   }
}
# Function to mount ISO and copy setup files
function Mount-And-ExtractISO {
   param (
       [string]$ISOPath,
       [string]$ExtractPath
   )
   try {
       Write-Output "Mounting ISO: $ISOPath"
       $mountResult = Mount-DiskImage -ImagePath $ISOPath -PassThru
       # Wait for the volume to be available
       Start-Sleep -Seconds 5
       $driveLetter = ($mountResult | Get-Volume).DriveLetter
       if (-not $driveLetter) {
           Write-Error "Failed to retrieve the drive letter of the mounted ISO."
           Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue
           exit 1
       }
       $mountedPath = "$($driveLetter):\"
       Write-Output "ISO mounted at $mountedPath"
       # Copy setup files
       Write-Output "Copying setup files to $ExtractPath"
       Copy-Item -Path "$mountedPath*" -Destination $ExtractPath -Recurse -Force -Verbose
       # Dismount the ISO
       Write-Output "Dismounting ISO."
       Dismount-DiskImage -ImagePath $ISOPath
       Write-Output "Setup files copied successfully."
   }
   catch {
       Write-Error "Error during mounting or extracting ISO: $_"
       # Attempt to dismount if mounted
       Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue
       exit 1
   }
}
# Function to initiate the Windows upgrade
function Start-WindowsUpgrade {
   param (
       [string]$SetupPath,
       [string]$Arguments
   )
   try {
       Write-Output "Starting Windows upgrade with arguments: $Arguments"
       Start-Process -NoNewWindow -Wait -FilePath $SetupPath -ArgumentList $Arguments -Verb RunAs
       Write-Output "Windows upgrade process initiated."
   }
   catch {
       Write-Error "Error during Windows upgrade initiation: $_"
       exit 1
   }
}
# Main script execution
try {
   # Ensure the script is running with administrative privileges
   Ensure-Administrator
   # Define variables
   $SetupDirectory = "C:\WindowsSetup"
   $FidoScriptPath = ".\Fido.ps1"
   # Create setup directory if it doesn't exist
   Create-DirectoryIfNotExists -Path $SetupDirectory
   # Verify Fido.ps1 exists
   if (-not (Test-Path -Path $FidoScriptPath)) {
       Write-Error "Fido.ps1 not found at path: $FidoScriptPath"
       exit 1
   }
   # Configuration parameters
   $Release = "22H2"
   $WinEdition = "Pro"        # Change as needed (e.g., Home, Pro, Enterprise)
   $Architecture = "x64"      # Change to "x86" if needed
   $Language = "English"      # Change as needed
   $DownloadPath = "$SetupDirectory\Windows_22H2.iso"
   # Download the Windows ISO
   Download-WindowsISO -FidoScriptPath $FidoScriptPath `
                      -WinEdition $WinEdition `
                      -Release $Release `
                      -Architecture $Architecture `
                      -Language $Language `
                      -DestinationPath $DownloadPath
   # Mount the ISO and extract setup files
   Mount-And-ExtractISO -ISOPath $DownloadPath `
                       -ExtractPath $SetupDirectory
   # Remove the ISO after extraction
   Write-Output "Removing ISO file: $DownloadPath"
   Remove-Item -Path $DownloadPath -Force
   # Define upgrade arguments
   $ArgumentList = "/auto upgrade /eula accept /quiet /noreboot"
   # Path to setup.exe
   $SetupExePath = "$SetupDirectory\setup.exe"
   if (-not (Test-Path -Path $SetupExePath)) {
       Write-Error "setup.exe not found at path: $SetupExePath"
       exit 1
   }
   # Initiate the Windows upgrade
   Start-WindowsUpgrade -SetupPath $SetupExePath -Arguments $ArgumentList
   Write-Output "Windows upgrade script completed successfully."
}
catch {
   Write-Error "An unexpected error occurred: $_"
   exit 1
}
