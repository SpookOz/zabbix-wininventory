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

$outputWinOS = "- CHQ.WinOS "
$outputWinOS += '"'
$outputWinOS += "$($WinOS)"
$outputWinOS += '"'

$outputModelNum = "- CHQ.ModelNum "
$outputModelNum += '"'
$outputModelNum += "$($ModelNum)"
$outputModelNum += '"'

$outputManuf = "- CHQ.Manuf "
$outputManuf += '"'
$outputManuf += "$($Manuf)"
$outputManuf += '"'

$outputWinDomain = "- CHQ.WinDomain "
$outputWinDomain += '"'
$outputWinDomain += "$($WinDomain)"
$outputWinDomain += '"'

$outputOwner = "- CHQ.Owner "
$outputOwner += '"'
$outputOwner += "$($Owner)"
$outputOwner += '"'

$outputLoggedon = "- CHQ.Loggedon "
$outputLoggedon += '"'
$outputLoggedon += "$($Loggedon)"
$outputLoggedon += '"'

$outputOSInstallDate = "- CHQ.OSInstallDate "
$outputOSInstallDate += '"'
$outputOSInstallDate += "$($OSInstallDate)"
$outputOSInstallDate += '"'

$outputBIOSDate = "- CHQ.BIOSDate "
$outputBIOSDate += '"'
$outputBIOSDate += "$($BIOSDate)"
$outputBIOSDate += '"'

Write-Output "- CHQ.WinArch $Winarch" | Out-File -Encoding "ASCII" -FilePath $env:temp$SenderargInvStatus
Add-Content $env:temp$SenderargInvStatus $outputWinOS
Add-Content $env:temp$SenderargInvStatus "- CHQ.WinBuild $WinBuild"
Add-Content $env:temp$SenderargInvStatus $outputModelNum
Add-Content $env:temp$SenderargInvStatus $outputManuf
Add-Content $env:temp$SenderargInvStatus "- CHQ.SerialNum $SerialNum"
Add-Content $env:temp$SenderargInvStatus $outputWinDomain
Add-Content $env:temp$SenderargInvStatus $outputOwner
Add-Content $env:temp$SenderargInvStatus $outputLoggedon
Add-Content $env:temp$SenderargInvStatus "- CHQ.IPAddress $IPAddress"
Add-Content $env:temp$SenderargInvStatus "- CHQ.IPGateway $IPGateway"
Add-Content $env:temp$SenderargInvStatus "- CHQ.PrimDNSServer $PrimDNSServer"
Add-Content $env:temp$SenderargInvStatus $outputBIOSDate
Add-Content $env:temp$SenderargInvStatus $outputOSInstallDate

# ------------------------------------------------------------------------- #
# This part sends the information in the temp file to Zabbix
# ------------------------------------------------------------------------- #

& $Sender $Senderarg1 $Senderarg2 $Senderarg3 $Senderarg4 $env:temp$SenderargInvStatus