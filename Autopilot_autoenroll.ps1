# Ensure the script is running with administrative privileges
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
   Write-Warning "You need to run this script as an Administrator."
   exit
}
# Define the registry path
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin"
# Check if the registry key exists; if not, create it
if (-not (Test-Path $registryPath)) {
   try {
       New-Item -Path $registryPath -Force | Out-Null
       Write-Output "Created registry path: $registryPath"
   }
   catch {
       Write-Error "Failed to create registry path: $_"
       exit
   }
}
# Set the AutoWorkplaceJoin value to enable auto-enrollment
try {
   Set-ItemProperty -Path $registryPath -Name "AutoWorkplaceJoin" -Value 1 -Type DWord
   Write-Output "Successfully set 'AutoWorkplaceJoin' to 1 to enable auto-enrollment for Intune."
}
catch {
   Write-Error "Failed to set 'AutoWorkplaceJoin': $_"
   exit
}
# Optional: Verify the setting
try {
   $currentValue = Get-ItemProperty -Path $registryPath -Name "AutoWorkplaceJoin"
   if ($currentValue.AutoWorkplaceJoin -eq 1) {
       Write-Output "Verification successful: 'AutoWorkplaceJoin' is set to 1."
   }
   else {
       Write-Warning "Verification failed: 'AutoWorkplaceJoin' is not set to 1."
   }
}
catch {
   Write-Error "Failed to verify 'AutoWorkplaceJoin': $_"