# Define variables
$InstallerUrl = "https://dl.dell.com/FOLDER11914128M/1/Dell-Command-Update-Windows-Universal-Application_9M35M_WIN_5.4.0_A00.EXE"
$InstallerPath = "$env:TEMP\Dell-Command-Update-Windows-Universal.exe"
$LogPath = "$env:TEMP\DellCommandUpdateInstall.log"

# Download the installer
Write-Host "Downloading Dell Command Update..." -ForegroundColor Green
try {
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -ErrorAction Stop
    Write-Host "Download completed: $InstallerPath" -ForegroundColor Green
} catch {
    Write-Host "Failed to download Dell Command Update. Error: $_" -ForegroundColor Red
    exit 1
}

# Install the application silently
Write-Host "Installing Dell Command Update..." -ForegroundColor Green
try {
    Start-Process -FilePath $InstallerPath -ArgumentList "/s" -Wait -NoNewWindow
    Write-Host "Installation completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to install Dell Command Update. Error: $_" -ForegroundColor Red
    exit 1
}

# Run Dell Command Update to perform an update check
$DCUPath = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"

if (Test-Path $DCUPath) {
    Write-Host "Running Dell Command Update to check for updates..." -ForegroundColor Green
    try {
        Start-Process -FilePath $DCUPath -ArgumentList "/scan" -Wait -NoNewWindow
        Write-Host "Dell Command Update completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to run Dell Command Update. Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Dell Command Update executable not found at $DCUPath. Please verify the installation." -ForegroundColor Red
    exit 1
}

# Cleanup the installer
Write-Host "Cleaning up downloaded installer..." -ForegroundColor Green
Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue
Write-Host "Script completed successfully." -ForegroundColor Green
