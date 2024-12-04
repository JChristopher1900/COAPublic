# Define the root directory (assuming icons are in the same directory as the script)
$rootDir = $PSScriptRoot
# Define the destination directory for icons
$iconDestDir = "C:\ProgramData\Icons"
# Create the directory if it doesn't exist
if (-not (Test-Path -Path $iconDestDir)) {
   New-Item -Path $iconDestDir -ItemType Directory
   Write-Host "Created directory: $iconDestDir"
}
# Define the icon files to copy
$iconFiles = @(
   "atl-connect-icon.ico"
   
)
# Copy icons to the destination directory
foreach ($icon in $iconFiles) {
   $sourcePath = Join-Path -Path $rootDir -ChildPath $icon
   $destPath = Join-Path -Path $iconDestDir -ChildPath $icon
   if (Test-Path -Path $sourcePath) {
       Copy-Item -Path $sourcePath -Destination $destPath -Force
       Write-Host "Copied $icon to $iconDestDir"
   } else {
       Write-Host "Icon $icon not found in root directory. Skipping..."
   }
}
# Define the shortcut details with updated icon paths
$shortcuts = @(
   @{
       Name      = "ATL Connect"
       Url       = "https://coa311.crm9.dynamics.com/main.aspx"
       Path      = "$env:Public\Desktop\ATL Connect.lnk"
       IconPath  = "$iconDestDir\atl-connect-icon.ico"
   }

)
# Create shortcuts if they don't already exist
foreach ($shortcut in $shortcuts) {
   $shortcutPath = $shortcut.Path
   if (-not (Test-Path -Path $shortcutPath)) {
       $wshShell = New-Object -ComObject WScript.Shell
       $shortcutObject = $wshShell.CreateShortcut($shortcutPath)
       $shortcutObject.TargetPath = $shortcut.Url
       $shortcutObject.IconLocation = $shortcut.IconPath
       $shortcutObject.Save()
       Write-Host "Created shortcut: $($shortcut.Name) with icon $($shortcut.IconPath)"
   } else {
       Write-Host "Shortcut for $($shortcut.Name) already exists. Skipping..."
   }
}
