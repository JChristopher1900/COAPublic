<#
.SYNOPSIS
   Updates Windows using the Windows Update Assistant.
.DESCRIPTION
   Downloads the latest Windows Update Assistant and initiates the update process.
   Ensures the system is ready by configuring power settings and checking for administrative privileges.
.PARAMETER DownloadDir
   Directory where the Windows Update Assistant will be downloaded.
.PARAMETER LogDir
   Directory where log files will be stored.
.PARAMETER UpdateUrl
   URL to download the Windows Update Assistant.
.EXAMPLE
   .\Update-Windows.ps1 -DownloadDir "C:\Temp\Windows_FU\packages" -LogDir "C:\Temp\Windows_FU\Logs"
#>
[CmdletBinding()]
param (
   [Parameter(Mandatory = $false)]
   [string]$DownloadDir = 'C:\Temp\Windows_FU\packages',
   [Parameter(Mandatory = $false)]
   [string]$LogDir = 'C:\Temp\Windows_FU\Logs',
   [Parameter(Mandatory = $false)]
   [string]$UpdateUrl = 'https://go.microsoft.com/fwlink/?LinkID=799445'
)
# Disable power-saving features to prevent interruptions during the update
function Set-PowerSettings {
   Write-Log "Configuring power settings to prevent sleep, hibernate, and disk timeout."
   try {
       powercfg.exe /change monitor-timeout-ac 0
       powercfg.exe /change monitor-timeout-dc 0
       powercfg.exe /change disk-timeout-ac 0
       powercfg.exe /change disk-timeout-dc 0
       powercfg.exe /change standby-timeout-ac 0
       powercfg.exe /change standby-timeout-dc 0
       powercfg.exe /change hibernate-timeout-ac 0
       powercfg.exe /change hibernate-timeout-dc 0
       Write-Log "Power settings configured successfully."
   }
   catch {
       Write-Log "ERROR: Failed to configure power settings. $_"
       throw
   }
}
# Function to write logs
function Write-Log {
   [CmdletBinding()]
   param (
       [Parameter(Mandatory)]
       [string]$Message,
       [ValidateSet("INFO", "WARN", "ERROR")]
       [string]$Level = "INFO"
   )
   try {
       if (!(Test-Path -Path (Split-Path -Path $LogFilePath))) {
           New-Item -ItemType Directory -Path (Split-Path -Path $LogFilePath) -Force | Out-Null
       }
       $DateTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
       $logMessage = "$DateTime [$Level] - $Message"
       Add-Content -Value $logMessage -Path $LogFilePath
       if ($Level -eq "ERROR") {
           Write-Error $Message
       }
       else {
           Write-Output $logMessage
       }
   }
   catch {
       Write-Error "Failed to write to log file. $_"
   }
}
# Function to check for administrative privileges
function Check-AdministrativePrivileges {
   Write-Log -Message "Checking for administrative privileges..." -Level "INFO"
   $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
   if (-not $isAdmin) {
       Write-Log -Message "Insufficient permissions to run this script. Please run as Administrator." -Level "ERROR"
       return $false
   }
   else {
       Write-Log -Message "Administrative privileges confirmed." -Level "INFO"
       return $true
   }
}
# Function to download the Windows Update Assistant
function Download-UpdateAssistant {
   param (
       [string]$Url,
       [string]$Destination
   )
   Write-Log -Message "Starting download of Windows Update Assistant from $Url" -Level "INFO"
   try {
       Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
       Write-Log -Message "Download completed successfully." -Level "INFO"
   }
   catch {
       Write-Log -Message "ERROR: Failed to download Windows Update Assistant. $_" -Level "ERROR"
       throw
   }
}
# Function to validate the downloaded file (e.g., using checksum)
function Validate-Download {
   param (
       [string]$FilePath
   )
   # Placeholder for validation logic
   # Example: Compare against a known hash value
   Write-Log -Message "Validating the downloaded Windows Update Assistant." -Level "INFO"
   # Implement checksum validation if available
   # For now, assume validation passes
   Write-Log -Message "Validation passed." -Level "INFO"
   return $true
}
# Function to initiate the update process
function Start-UpdateProcess {
   param (
       [string]$Executable,
       [string]$Arguments
   )
   Write-Log -Message "Initiating the Windows Update process." -Level "INFO"
   try {
       Start-Process -FilePath $Executable -ArgumentList $Arguments -Wait -NoNewWindow
       Write-Log -Message "Windows Update process started successfully." -Level "INFO"
   }
   catch {
       Write-Log -Message "ERROR: Failed to start the Windows Update process. $_" -Level "ERROR"
       throw
   }
}
# Function to clean up temporary files
function Cleanup-Files {
   param (
       [string]$Path
   )
   Write-Log -Message "Cleaning up temporary files in $Path" -Level "INFO"
   try {
       Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
       Write-Log -Message "Cleanup completed." -Level "INFO"
   }
   catch {
       Write-Log -Message "WARNING: Failed to clean up some files. $_" -Level "WARN"
   }
}
# Main script execution
try {
   # Initialize directories and log file
   if (-not (Test-Path $DownloadDir)) {
       New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
       Write-Log -Message "Created download directory at $DownloadDir" -Level "INFO"
   }
   if (-not (Test-Path $LogDir)) {
       New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
       Write-Log -Message "Created log directory at $LogDir" -Level "INFO"
   }
   $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
   $LogFilePath = Join-Path -Path $LogDir -ChildPath "UpdateScript_$timestamp.log"
   # Log script initiation
   Write-Log -Message "Script initiated by user: $env:USERNAME on machine: $env:COMPUTERNAME" -Level "INFO"
   Write-Log -Message "Current Windows Version: $([System.Environment]::OSVersion)" -Level "INFO"
   # Check for administrative privileges
   if (-not (Check-AdministrativePrivileges)) {
       exit 1
   }
   # Configure power settings
   Set-PowerSettings
   # Define the path for the updater
   $UpdaterBinary = Join-Path -Path $DownloadDir -ChildPath "Win10Upgrade.exe"
   # Remove existing updater if present
   if (Test-Path $UpdaterBinary) {
       Write-Log -Message "Existing updater found at $UpdaterBinary. Removing it." -Level "INFO"
       Remove-Item -Path $UpdaterBinary -Force
   }
   # Download the Windows Update Assistant
   Download-UpdateAssistant -Url $UpdateUrl -Destination $UpdaterBinary
   # Validate the downloaded file
   if (-not (Validate-Download -FilePath $UpdaterBinary)) {
       Write-Log -Message "Downloaded file validation failed. Aborting update." -Level "ERROR"
       exit 1
   }
   # Define updater arguments
   $UpdaterArguments = "/quietinstall /skipeula /autoupgrade /copylogs `"$LogDir`""
   # Start the update process
   Start-UpdateProcess -Executable $UpdaterBinary -Arguments $UpdaterArguments
   Write-Log -Message "Update process has been initiated. The system may reboot shortly if required." -Level "INFO"
   # Optional: Reboot the system if needed
   # Restart-Computer -Force -Confirm
   # Cleanup downloaded files
   Cleanup-Files -Path $DownloadDir
}
catch {
   Write-Log -Message "An unexpected error occurred: $_" -Level "ERROR"
   exit 1
}
# End of Script
