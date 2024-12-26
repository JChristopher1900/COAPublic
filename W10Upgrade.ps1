<#
.SYNOPSIS
   Automatically upgrades any edition of Windows 10 to Windows 10 version 22H2 without user intervention.
.DESCRIPTION
   This script automates the process of downloading Fido.ps1, retrieving the Windows 10 22H2 ISO, mounting it, copying the setup files, and initiating the upgrade process silently.
.NOTES
   - Requires administrative privileges.
   - Ensure you have a stable internet connection.
   - Sufficient disk space in C:\WindowsSetup is necessary.
#>
param (
   [string]$FidoUrl = "https://raw.githubusercontent.com/pbatard/Fido/refs/heads/master/Fido.ps1",
   [string]$FidoScriptPath = "C:\WindowsSetup\Fido.ps1",
   [string]$LogFilePath = "C:\WindowsSetup\UpgradeLog.txt",
   [string]$SetupDirectory = "C:\WindowsSetup",
   [string]$Release = "22H2",
   [string]$WinEdition = "Pro",         # Options: Home, Pro, Enterprise, etc.
   [string]$Architecture = "x64",       # Options: x64, x86
   [string]$Language = "English",       # Specify desired language
   [string]$DownloadPath = "C:\WindowsSetup\Windows_22H2.iso",
   [string]$ArgumentList = "/auto upgrade /eula accept /quiet /noreboot /dynamicupdate disable"
)
# Function to log messages
function Write-Log {
   param (
       [string]$Message,
       [string]$Level = "INFO"
   )
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logMessage = "$timestamp [$Level] $Message"
   Write-Output $logMessage
   Add-Content -Path $LogFilePath -Value $logMessage
}
# Function to ensure the script runs as Administrator
function Ensure-Administrator {
   if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
       Write-Log "This script must be run as an Administrator." "ERROR"
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
           Write-Log "Created directory: $Path"
       }
       catch {
           Write-Log "Failed to create directory $Path. $_" "ERROR"
           exit 1
       }
   }
   else {
       Write-Log "Directory already exists: $Path"
   }
}
# Function to download a file with retry logic
function Download-FileWithRetry {
   param (
       [string]$Url,
       [string]$DestinationPath,
       [int]$MaxRetries = 3,
       [int]$DelaySeconds = 10
   )
   $attempt = 0
   while ($attempt -lt $MaxRetries) {
       try {
           Write-Log "Attempting to download from $Url (Attempt $($attempt + 1))"
           Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -UseBasicParsing -ErrorAction Stop
           Write-Log "Successfully downloaded $Url to $DestinationPath"
           return
       }
       catch {
           $attempt++
           Write-Log "Failed to download $Url. Attempt $attempt of $MaxRetries. Error: $_" "WARNING"
           if ($attempt -lt $MaxRetries) {
               Write-Log "Retrying in $DelaySeconds seconds..."
               Start-Sleep -Seconds $DelaySeconds
           }
           else {
               Write-Log "Exceeded maximum retry attempts for downloading $Url." "ERROR"
               exit 1
           }
       }
   }
}
# Function to download the Windows ISO using Fido
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
       # Import Fido script
       Write-Log "Importing Fido script from $FidoScriptPath"
       . $FidoScriptPath
       # Get download URL using Fido
       Write-Log "Retrieving download URL using Fido..."
       $URI = Fido -Win 10 -Rel $Release -Arch $Architecture -Ed $WinEdition -Lang $Language -GetUrl
       if (-not $URI) {
           Write-Log "Failed to retrieve download URL using Fido." "ERROR"
           exit 1
       }
       Write-Log "Download URL obtained: $URI"
       # Start BITS transfer
       Write-Log "Starting download of Windows 10 $Release ISO..."
       $bitsJob = Start-BitsTransfer -Source $URI -Destination $DestinationPath -Asynchronous -Priority Foreground
       # Monitor the BITS job
       while (($bitsJob | Get-BitsTransfer).JobState -ne "Transferred") {
           $bitsInfo = Get-BitsTransfer -JobId $bitsJob.JobId
           if ($bitsInfo.BytesTotal -gt 0) {
               $progress = [math]::Round( ($bitsInfo.BytesTransferred / $bitsInfo.BytesTotal) * 100, 2 )
               Write-Log "Downloading... Progress: $progress%"
           }
           else {
               Write-Log "Downloading... Progress: Calculating..."
           }
           Start-Sleep -Seconds 10
       }
       # Complete the transfer
       Complete-BitsTransfer -BitsJob $bitsJob
       Write-Log "Download completed successfully."
   }
   catch {
       Write-Log "Error during download: $_" "ERROR"
       # Cleanup partial download
       if (Test-Path -Path $DestinationPath) {
           Remove-Item -Path $DestinationPath -Force
           Write-Log "Partial download removed: $DestinationPath"
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
       Write-Log "Mounting ISO: $ISOPath"
       $mountResult = Mount-DiskImage -ImagePath $ISOPath -PassThru -ErrorAction Stop
       # Wait for the volume to be available
       Start-Sleep -Seconds 10
       $driveLetter = ($mountResult | Get-Volume).DriveLetter
       if (-not $driveLetter) {
           Write-Log "Failed to retrieve the drive letter of the mounted ISO." "ERROR"
           Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue
           exit 1
       }
       $mountedPath = "$($driveLetter):\"
       Write-Log "ISO mounted at $mountedPath"
       # Copy setup files
       Write-Log "Copying setup files to $ExtractPath"
       robocopy "$mountedPath" "$ExtractPath" /MIR /COPYALL /R:3 /W:5 /LOG+:$LogFilePath
       # Check if setup.exe exists after copying
       $setupExePath = Join-Path -Path $ExtractPath -ChildPath "setup.exe"
       if (-not (Test-Path -Path $setupExePath)) {
           Write-Log "setup.exe not found after copying. Possible copy failure." "ERROR"
           Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue
           exit 1
       }
       Write-Log "Setup files copied successfully."
       # Dismount the ISO
       Write-Log "Dismounting ISO."
       Dismount-DiskImage -ImagePath $ISOPath
   }
   catch {
       Write-Log "Error during mounting or extracting ISO: $_" "ERROR"
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
       Write-Log "Starting Windows upgrade with arguments: $Arguments"
       Start-Process -NoNewWindow -Wait -FilePath $SetupPath -ArgumentList $Arguments -Verb RunAs
       Write-Log "Windows upgrade process initiated."
   }
   catch {
       Write-Log "Error during Windows upgrade initiation: $_" "ERROR"
       exit 1
   }
}
# Main script execution
try {
   # Ensure the script is running with administrative privileges
   Ensure-Administrator
   # Create setup directory if it doesn't exist
   Create-DirectoryIfNotExists -Path $SetupDirectory
   # Initialize log file
   if (-not (Test-Path -Path $LogFilePath)) {
       New-Item -ItemType File -Path $LogFilePath -Force | Out-Null
   }
   Write-Log "Upgrade script started."
   # Download Fido.ps1 if not present
   if (-not (Test-Path -Path $FidoScriptPath)) {
       Write-Log "Fido.ps1 not found. Downloading from $FidoUrl"
       Download-FileWithRetry -Url $FidoUrl -DestinationPath $FidoScriptPath
   }
   else {
       Write-Log "Fido.ps1 already exists at $FidoScriptPath"
   }
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
   Write-Log "Removing ISO file: $DownloadPath"
   Remove-Item -Path $DownloadPath -Force
   Write-Log "ISO file removed."
   # Define upgrade arguments
   # The /noreboot flag prevents automatic reboot. To allow automatic reboot, remove /noreboot.
   # Similarly, /dynamicupdate disable prevents dynamic updates during upgrade.
   # Adjust arguments as needed for your environment.
   # For complete silence, you might consider adding more flags based on setup.exe documentation.
   $ArgumentList = "/auto upgrade /eula accept /quiet /noreboot /dynamicupdate disable"
   # Path to setup.exe
   $SetupExePath = Join-Path -Path $SetupDirectory -ChildPath "setup.exe"
   if (-not (Test-Path -Path $SetupExePath)) {
       Write-Log "setup.exe not found at path: $SetupExePath" "ERROR"
       exit 1
   }
   # Initiate the Windows upgrade
   Start-WindowsUpgrade -SetupPath $SetupExePath -Arguments $ArgumentList
   # Optionally, schedule a restart after upgrade
   # Uncomment the following lines if you want the system to reboot automatically after upgrade
   #
   # Write-Log "Scheduling system restart in 5 minutes."
   # shutdown.exe /r /t 300 /c "Windows 10 22H2 Upgrade - Restarting in 5 minutes."
   Write-Log "Windows upgrade script completed successfully."
}
catch {
   Write-Log "An unexpected error occurred: $_" "ERROR"
   exit 1
}
has context menu
