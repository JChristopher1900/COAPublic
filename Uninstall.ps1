# Define the paths for the shortcut and the icon
$shortcutPath = "$env:Public\Desktop\ATL Connect.lnk"
$iconFilePath = "C:\ProgramData\Icons\atl-connect-icon.ico"
$iconDestDir = "C:\ProgramData\Icons"

# Remove the shortcut if it exists
if (Test-Path -Path $shortcutPath) {
    Remove-Item -Path $shortcutPath -Force
    Write-Host "Removed shortcut: $shortcutPath"
} else {
    Write-Host "Shortcut not found. Skipping..."
}

# Remove the icon file if it exists
if (Test-Path -Path $iconFilePath) {
    Remove-Item -Path $iconFilePath -Force
    Write-Host "Removed icon file: $iconFilePath"
} else {
    Write-Host "Icon file not found. Skipping..."
}

# Remove the icon directory if it is empty
if ((Test-Path -Path $iconDestDir) -and (Get-ChildItem -Path $iconDestDir | Measure-Object).Count -eq 0) {
    Remove-Item -Path $iconDestDir -Force
    Write-Host "Removed empty directory: $iconDestDir"
} else {
    Write-Host "Directory not empty or not found. Skipping..."
}