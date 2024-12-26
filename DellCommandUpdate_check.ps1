# Script to check and apply updates using Dell Command Update
# Potential paths for Dell Command Update
$Paths = @(
   "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe",
   "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
)
# Find the executable path
$DellCommandPath = $Paths | Where-Object { Test-Path $_ }
if (-Not $DellCommandPath) {
   Write-Host "Dell Command Update is not installed in either location. Please install it first." -ForegroundColor Red
   exit 1
}
# Display a message indicating the update process is starting
Write-Host "Dell Command Update found at: $DellCommandPath" -ForegroundColor Green
# Run Dell Command Update to check for updates
Write-Host "Checking for updates..."
& $DellCommandPath /check
# Apply all available updates
Write-Host "Applying updates..."
& $DellCommandPath /applyUpdates -noreboot
# Check if a reboot is required
Write-Host "Checking if a reboot is required..."
& $DellCommandPath /rebootCheck
if ($LASTEXITCODE -eq 3010) {
   Write-Host "Reboot is required. Please reboot the system to complete the update." -ForegroundColor Yellow
} else {
   Write-Host "No reboot required. Updates applied successfully." -ForegroundColor Green
}
