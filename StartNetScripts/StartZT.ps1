#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$Product = (Get-MyComputerProduct)
$Model = (Get-MyComputerModel)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$OSVersion = 'Windows 11'
$OSReleaseID = '24H2'
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Pro'
$OSActivation = 'Retail'
$OSLanguage = 'de-de'
 
#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$true
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$True
    WindowsUpdateDrivers = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$false
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
    CheckSHA1 = [bool]$true
    ZTI  = [bool]$true
    Firmware = [bool]$true
}

$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID

if ($DriverPack){
    $Global:MyOSDCloud.DriverPackName = $DriverPack.Name
}

if ($Manufacturer -eq 'Lenovo') {
    Install-Module -Name 'lsuclient' -Force -Confirm:$false -SkipPublisherCheck -TrustRepository
    $updates = get-lsupdate
    $updates | where-object {$_.type -eq 'BIOS'} | Install-LSUpdate -Verbose
}
 
if (Test-HPIASupport){
    Write-Host "Detected HP Device, Enabling HPIA, HP BIOS and HP TPM Updates"
    
    $Global:MyOSDCloud.HPTPMUpdate = [bool]$True
    $Global:MyOSDCloud.HPIAALL = [bool]$true
    $Global:MyOSDCloud.HPBIOSUpdate = [bool]$true

    #Set HP BIOS Settings to what I want:
    #iex (irm https://raw.githubusercontent.com/gwblok/garytown/master/OSD/CloudOSD/Manage-HPBiosSettings.ps1)
    #Manage-HPBiosSettings -SetSettings
}

#Launch OSDCloud
Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"
 
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

write-host "OSDCloud Process Complete, Running Custom Actions From Script Before Reboot"

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
powershell.exe -Command Set-ExecutionPolicy RemoteSigned -Force
powershell.exe -Command "& {IEX (IRM https://raw.githubusercontent.com/AWcancom/OSDCloud/refs/heads/main/CloudScripts/CleanUp.ps1)}"
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#Copy CMTrace Local:
if (Test-path -path "x:\windows\system32\cmtrace.exe"){
    copy-item "x:\windows\system32\cmtrace.exe" -Destination "C:\Windows\System32\cmtrace.exe" -verbose
}

#Copy AutopilotScript from USB Drive to Windows Installation so it can be executed as part of SetupComplete
if (Test-path -path "x:\OSDCloud\Config\Scripts\AutoPilot.ps1"){
    copy-item "x:\OSDCloud\Config\Scripts\AutoPilot.ps1" -Destination "c:\OSDCloud\Scripts\AutoPilot.ps1" -verbose
}

#powershell.exe -Command "& {IEX (IRM https://raw.githubusercontent.com/AWcancom/OSDCloud/refs/heads/main/CloudScripts/oobetasks.ps1)}"
#powershell.exe -Command "& {IEX (IRM https://raw.githubusercontent.com/AWcancom/OSDCloud/refs/heads/main/CloudScripts/CleanUp.ps1)}"
#powershell.exe -NoProfile -ExecutionPolicy Bypass "c:\OSDCloud\Scripts\AutoPilot.ps1"