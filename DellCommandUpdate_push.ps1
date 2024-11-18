$currentdate = Get-Date -format 'ddMMyyyy_HHmmss'
$dcucli = "${env:ProgramFiles}\Dell\CommandUpdate\dcu-cli.exe"
$logsfolder = "$env:Programdata\Dell\Logs"

#Download and install Dell Command Update 5.4 if it doesn't exist
if (!(test-path $dcucli)) {
$uri = 'https://dl.dell.com/FOLDER11914128M/1/Dell-Command-Update-Windows-Universal-Application_9M35M_WIN_5.4.0_A00.EXE'
Write-Host "DCU Cli doesn't seem to be present.. Attempting to download and install now.."
Invoke-WebRequest -uri $uri -outfile 'C:\Windows\temp\dcu54.exe' 
Start-Process "C:\Windows\Temp\dcu54.exe" -ArgumentList '/s' -Wait
Start-Sleep -Seconds 10
}

#Create new folder for logs in ProgramData - Change this based on your environment
if (!(Test-path $logsfolder)) {New-item $logsfolder -ItemType Directory}

#Apply all updates if any is found - including BIOS
Start-Process $dcucli -Wait -ArgumentList "/ApplyUpdates -outputlog=$logsfolder\dcucli_applyupdates_$currentdate.log"