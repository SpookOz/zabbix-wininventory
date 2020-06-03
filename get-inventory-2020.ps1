# Powershell script for Zabbix agents.

# Version 1.0

## This script will read a number of hardware inventory items from Windows and report them to Zabbix. It will also fill out the inventory tab for the host with the information it gathers.

#### Check https://github.com/SpookOz/zabbix-wininventory for the latest version of this script

# ------------------------------------------------------------------------- #
# Variables
# ------------------------------------------------------------------------- #

# Change $ZabbixInstallPath to wherever your Zabbix Agent is installed

$ZabbixInstallPath = "$Env:Programfiles\Zabbix Agent"

# Do not change the following variables unless you know what you are doing

$Sender = "$ZabbixInstallPath\zabbix_sender.exe"
$Senderarg1 = '-vv'
$Senderarg2 = '-c'
$Senderarg3 = "$ZabbixInstallPath\zabbix_agentd.conf"
$Senderarg4 = '-i'
$Senderarg5 = '-k'
$SenderargInvStatus = '\wininvstatus.txt'


# ------------------------------------------------------------------------- #
# This part gets the inventory data and writes it to a temp file
# ------------------------------------------------------------------------- #

$Winarch = Get-CimInstance Win32_OperatingSystem | Select-Object OSArchitecture | foreach { $_.OSArchitecture }
$WinOS = Get-CimInstance Win32_OperatingSystem | Select-Object Caption | foreach { $_.Caption }
$WinBuild = Get-CimInstance Win32_OperatingSystem | Select-Object BuildNumber | foreach { $_.BuildNumber }
$ModelNum = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Model | foreach { $_.Model }
$Manuf = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer | foreach { $_.Manufacturer }
$SerialNum = gwmi win32_bios | Select-Object SerialNumber | foreach { $_.SerialNumber }
$WinDomain = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Domain | foreach { $_.Domain }
$Owner = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object PrimaryOwnerName | foreach { $_.PrimaryOwnerName }
$Loggedon = Get-CimInstance -ClassName Win32_ComputerSystem  | Select-Object UserName | foreach { $_.UserName }
$IPAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).IPAddress | select-object -first 1
$IPGateway = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).DefaultIPGateway | select-object -first 1
$PrimDNSServer = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).DNSServerSearchOrder | select-object -first 1
$BIOS = Get-WmiObject -Class Win32_BIOS
$BIOSageInYears = (New-TimeSpan -Start ($BIOS.ConvertToDateTime($BIOS.releasedate).ToShortDateString()) -End $(Get-Date)).Days / 365
$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
$OSInstallDate = ($OperatingSystem.ConvertToDateTime($OperatingSystem.InstallDate).ToShortDateString())
$BIOSDate = $BIOS.ConvertToDateTime($BIOS.releasedate).ToShortDateString()

# ------------------------------------------------------------------------- #
# This part gets location information. It turns on location tracking. If this is a privacy concern, you can to next comment
# ------------------------------------------------------------------------- #

	If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location")) {
		New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force | Out-Null
	}
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Allow"
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 1
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 1

Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
$GeoWatcher.Start() #Begin resolving current locaton

while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
    Start-Sleep -Milliseconds 100 #Wait for discovery.
}  

if ($GeoWatcher.Permission -eq 'Denied'){
    $Latitude = '0'
    $Longitude = '0'
} else {
    $Latitude = $GeoWatcher.Position.Location | Select Latitude,Longitude | foreach { $_.Latitude }
    $Longitude = $GeoWatcher.Position.Location | Select Latitude,Longitude | foreach { $_.Longitude }
}

$outputGeoLocation = "- inv.Geolocation "
$outputGeoLocation += '"'
$outputGeoLocation += "$($Latitude)"
$outputGeoLocation += ' '
$outputGeoLocation += "$($Longitude)"
$outputGeoLocation += '"'

# ------------------------------------------------------------------------- #
# Delete above here to remove location data
# ------------------------------------------------------------------------- #

$outputWinOS = "- inv.WinOS "
$outputWinOS += '"'
$outputWinOS += "$($WinOS)"
$outputWinOS += '"'

$outputModelNum = "- inv.ModelNum "
$outputModelNum += '"'
$outputModelNum += "$($ModelNum)"
$outputModelNum += '"'

$outputManuf = "- inv.Manuf "
$outputManuf += '"'
$outputManuf += "$($Manuf)"
$outputManuf += '"'

$outputWinDomain = "- inv.WinDomain "
$outputWinDomain += '"'
$outputWinDomain += "$($WinDomain)"
$outputWinDomain += '"'

$outputOwner = "- inv.Owner "
$outputOwner += '"'
$outputOwner += "$($Owner)"
$outputOwner += '"'

$outputLoggedon = "- inv.Loggedon "
$outputLoggedon += '"'
$outputLoggedon += "$($Loggedon)"
$outputLoggedon += '"'

$outputOSInstallDate = "- inv.OSInstallDate "
$outputOSInstallDate += '"'
$outputOSInstallDate += "$($OSInstallDate)"
$outputOSInstallDate += '"'

$outputBIOSDate = "- inv.BIOSDate "
$outputBIOSDate += '"'
$outputBIOSDate += "$($BIOSDate)"
$outputBIOSDate += '"'



Write-Output "- inv.WinArch $Winarch" | Out-File -Encoding "ASCII" -FilePath $env:temp$SenderargInvStatus
Add-Content $env:temp$SenderargInvStatus $outputWinOS
Add-Content $env:temp$SenderargInvStatus "- inv.WinBuild $WinBuild"
Add-Content $env:temp$SenderargInvStatus $outputModelNum
Add-Content $env:temp$SenderargInvStatus $outputManuf
Add-Content $env:temp$SenderargInvStatus "- inv.SerialNum $SerialNum"
Add-Content $env:temp$SenderargInvStatus $outputWinDomain
Add-Content $env:temp$SenderargInvStatus $outputOwner
Add-Content $env:temp$SenderargInvStatus $outputLoggedon
Add-Content $env:temp$SenderargInvStatus "- inv.IPAddress $IPAddress"
Add-Content $env:temp$SenderargInvStatus "- inv.IPGateway $IPGateway"
Add-Content $env:temp$SenderargInvStatus "- inv.PrimDNSServer $PrimDNSServer"
Add-Content $env:temp$SenderargInvStatus $outputBIOSDate
Add-Content $env:temp$SenderargInvStatus $outputOSInstallDate
Add-Content $env:temp$SenderargInvStatus $outputGeoLocation

# ------------------------------------------------------------------------- #
# This part sends the information in the temp file to Zabbix
# ------------------------------------------------------------------------- #

& $Sender $Senderarg1 $Senderarg2 $Senderarg3 $Senderarg4 $env:temp$SenderargInvStatus