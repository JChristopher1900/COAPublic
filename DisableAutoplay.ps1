# Define the registry path and value
$registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$registryName = "NoDriveTypeAutoRun"
$desiredValue = 255
# Create the registry path if it doesn't exist
if (-not (Test-Path $registryPath)) {
   New-Item -Path $registryPath -Force | Out-Null
}
# Set the registry value
Set-ItemProperty -Path $registryPath -Name $registryName -Value $desiredValue -Type DWord
# Confirm the change
$currentValue = Get-ItemProperty -Path $registryPath -Name $registryName -ErrorAction SilentlyContinue
if ($currentValue.$registryName -eq $desiredValue) {
   Write-Output "AutoPlay has been disabled successfully."
   exit 0
} else {
   Write-Output "Failed to disable AutoPlay."
   exit 1
}
