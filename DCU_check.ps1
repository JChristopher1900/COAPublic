$DCU_folder = "C:\Program Files\Dell\CommandUpdate"
$DCU_report = "C:\Temp\Dell_report\update.log"
$DCU_exe = "$DCU_folder\dcu-cli.exe"
$DCU_category = "bios,firmware,driver,application,others"  # bios,firmware,driver,application,others
# $DCU_encryptionKey = "ADD ENC KEY" # Use the same value here as you use in /generateEncryptedPassword -encryptionKey=
#$DCU_encryptedPassword = "ADD ENC PWD" # Generate with dcu-cli.exe /generateEncryptedPassword -encryptionKey=<inline value> -password=<inlinevalue> -outputPath=<folderpath>

try{
    Start-Process $DCU_exe -ArgumentList "/applyUpdates -silent -reboot=disable -outputlog=$DCU_report" -Wait
    Write-Output "Installation completed"
}catch{
    Write-Error $_.Exception
}

# Usermanual: https://www.dell.com/support/manuals/de-ch/command-update/dellcommandupdate_rg/dell-command-%7C-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us
