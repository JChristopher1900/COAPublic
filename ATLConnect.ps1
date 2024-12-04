# Define the URL for the icon file on GitHub (raw link)
$iconUrl = "https://raw.githubusercontent.com/JChristopher1900/COAPublic/refs/heads/main/atl-connect-icon.ico"

# Define the destination directory for icons
$iconDestDir = "C:\ProgramData\Icons"

# Define the destination file path for the icon
$iconFileName = "atl-connect-icon.ico"
$iconFilePath = Join-Path -Path $iconDestDir -ChildPath $iconFileName

# Create the directory if it doesn't exist
if (-not (Test-Path -Path $iconDestDir)) {
   New-Item -Path $iconDestDir -ItemType Directory
   Write-Host "Created directory: $iconDestDir"
}

# Download the icon file from GitHub if it doesn't already exist
if (-not (Test-Path -Path $iconFilePath)) {
    try {
        Invoke-WebRequest -Uri $iconUrl -OutFile $iconFilePath
        Write-Host "Downloaded icon from GitHub to $iconFilePath"
    } catch {
        Write-Host "Failed to download icon from GitHub. Error: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "Icon already exists at $iconFilePath. Skipping download."
}

# Define the shortcut details with updated icon paths
$shortcuts = @(
   @{
       Name      = "ATL Connect"
       Url       = "https://coa311.crm9.dynamics.com/main.aspx"
       Path      = "$env:Public\Desktop\ATL Connect.lnk"
       IconPath  = $iconFilePath
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
