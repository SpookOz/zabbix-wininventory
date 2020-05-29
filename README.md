# zabbix-wininventory

This is a Zabbix template to collect some inventory and environmental information from hosts using active Windows agents. It also fills out the inventory tab in Zabbix with some of this information.
It has been tested on Zabbix 4.4.8 with Windows 8.1, 10 and server 2019. Currently needs testing with other Windows versions and other Zabbix versions.


## Features

Collects the following information from the host and fills out corresponding fields in Zabbix Inventory (AFAIK, the inventory field in Zabbix can not be modified, so some information does not map precisely to a corresponding field). In those cases, a different field has been used. The fields mapped can be modified).

Information Gathered --> Inventory Field

- Architecture --> HW architecture
- BIOS Date --> Serial number B
- Current Logged on User --> Secondary POC name
- IP Address (Internal) --> Host networks
- IP DNS Server --> Host subnet mask
- IP Gateway --> Host router
- Manufacturer --> Vendor
- Model Number --> Model
- OS Install Date --> OS (Full details)
- Owner --> Primary POC name
- Serial Number --> Serial number A
- Windows Build --> Software application A
- Windows Domain --> URL A
- Windows OS Version --> OS (Short)


## Requirements

- Has only been tested with Zabbix active agents. It will need tweaking to work with passive agents.
- At this stage it has only been tested on Windows 8.1, 10 and Server 2019. However, it should also work on server 2016 and Windows 7. Not sure about previous versions at this stage.
- You MUST have EnableRemoteCommands=1 in your conf file (so it can run the PS script).
- This script assumes the Zabbix client is installed in the Program Files directory. You will need to modify the Powershell script if it is not.
- To populate Inventory fields, Inventory must be set to Automatic. You can change this for existing hosts in Configuration → hosts → Select Host → Inventory. To make all new hosts' Inventory automatic, set this option in Administration → General → Other.
- You need a sub-folder called "plugins" in your Zabbix Agent install folder (eg: C:\Program Files\Zabbix Agent\plugins).


## Files Included

- wininventory.xml: Template to import into Zabbix.
- get-inventory-2020.ps1: Powershell script. By default, this will be downloaded automatically by the template, so you don't need to manually download it. However, if you want to turn that option off (for security or if you are making modifications to the script) this file must be placed in a "plugins" directory under your Zabbix Agent install folder (eg: C:\Program Files\Zabbix Agent\plugins).


## Installing

1. Ensure your Windows hosts have the agent installed and configured correctly and they are communicating with the Zabbix server.
2. Make sure you have edited the zabbix_agentd.conf file to include the line: EnableRemoteCommands=1.
3. Download Winupdates.xml template from Github and import the template in Zabbix and apply it to one or more Windows Hosts.

### Option 1 - Automatic Deployment of the Powershell script

This is the easiest option. The template will fetch the PowerShell script from Github. This is a good option if you need to deploy to a lot of hosts or you want updates to the PowerShell script to be fetched automatically. If you choose this option, anytime the PowerShell script is updated, the new script will be pushed to your hosts. If this is a security concern, you can disable this option.

1. Edit the template in Zabbix (Configuration → Templates → WinInventory).
2. Go to the "Items" tab.
3. You will see a disabled item called "Update WinInventory Template". Click on it to edit it.
4. Click the button to enable the item .
5. Optionally change the Interval if you want your hosts to fetch the PowerShell script more quickly.
6. Click "Update"
7. Once all hosts have received the script, it is a good idea to disable this item again Otherwise each host will re-download the script every day!
8. any time you want to update the scrip or deploy it to new hosts, just re-enable it again.

The item has a 1d update interval, so it may take up to a day for the PowerShell script to download. You can shorten this if you like.

### Option 2 - Deploy Powershell Script Manually

Choose this option if you want to make any changes to the PowerShell script or you prefer to deploy it yourself. You may need to change the agent install path if you don't have a default install (C:\Program Files\Zabbix Agent).

1. Create a sub-folder called "plugins" in your Zabbix Agent install folder (eg: C:\Program Files\Zabbix Agent\plugins).
2. Download get-inventory-2020.ps1 from Github (https://git.io/Jfon6) and make any changes you need to it. Check the .ps file for instructions on making changes.
3. Copy get-inventory-2020.ps1 to the plugins directory.



### Dashboard

You can add a widget to your Dashboard by choosing type: Data overview and application "Winupdates-Panel".