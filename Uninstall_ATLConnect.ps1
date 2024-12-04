# Uninstall Script for Removing Icons and Shortcuts
# Define the root directory (assuming icons are in the same directory as the script)
$rootDir = $PSScriptRoot
# Define the destination directory for icons
$iconDestDir = "C:\ProgramData\Icons"
# Define the icon files to remove
$iconFiles = @(
   "atl-connect-icon.ico"
)
# Remove icon files from the destination directory
foreach ($icon in $iconFiles) {
   $iconPath = Join-Path -Path $iconDestDir -ChildPath $icon
   if (Test-Path -Path $iconPath) {
       try {
           Remove-Item -Path $iconPath -Force -ErrorAction Stop
           Write-Host "Removed icon: $iconPath"
       } catch {
           Write-Host "Failed to remove icon: $iconPath. Error: $_"
       }
   } else {
       Write-Host "Icon $iconPath does not exist. Skipping..."
   }
}
# Define the shortcuts to remove
$shortcuts = @(
   @{
       Name = "ATL Connect"
       Path = "$env:Public\Desktop\ATL Connect.lnk"
   }
)
# Remove shortcuts if they exist
foreach ($shortcut in $shortcuts) {
   $shortcutPath = $shortcut.Path
   if (Test-Path -Path $shortcutPath) {
       try {
           Remove-Item -Path $shortcutPath -Force -ErrorAction Stop
           Write-Host "Removed shortcut: $($shortcut.Name)"
       } catch {
           Write-Host "Failed to remove shortcut: $shortcutPath. Error: $_"
       }
   } else {
       Write-Host "Shortcut for $($shortcut.Name) does not exist. Skipping..."
   }
}
# Optionally, remove the icon destination directory if empty
if (Test-Path -Path $iconDestDir) {
   $items = Get-ChildItem -Path $iconDestDir -ErrorAction SilentlyContinue
   if ($items.Count -eq 0) {
       try {
           Remove-Item -Path $iconDestDir -Force -ErrorAction Stop
           Write-Host "Removed directory: $iconDestDir"
       } catch {
           Write-Host "Failed to remove directory: $iconDestDir. Error: $_"
       }
   } else {
       Write-Host "Directory $iconDestDir is not empty. Skipping removal."
   }
} else {
   Write-Host "Icon directory $iconDestDir does not exist. Skipping..."
}
