<#
    .SYNOPSIS
        Install / Setup pre-requisites for a System8 installatikon, network partly omitted
    .DESCRIPTION
    set Local Admin, Timezone, Hostname, Disable Server Manager autostart, Disable IE ESC, Enable RDP, Disable NETBIOS (optional),
    Disable IPv6, Enable File and Printer sharing, Add firewall rules on some hosts, Set task after restart,
    .NOTES
        I assume no liability for the function, 
        the use and the consequences of the use of this freely available script.
        PowerShell is a product of Microsoft Corporation.
        payomagic 2023/3
    .COMPONENT
        Requires Module ActiveDirectory
    .LINK
        https://github.com/payomagic/powershell
   .Parameter -all parameters specified in the script
#>


# github.com/payomagic
#
# Whole installation should take approx 30mins alltogether

$Host_Name = Read-Host -Prompt " Insert Hostname as per NETPLAN : "
$netbdisQ = Read-Host -Prompt "Do you want to disable NETBIOS over TCP/IP (used on 800xA servers only)? yes/no"
$disISATAPQ = Read-Host -Prompt "Do you want to disable ISATAP (IPv6)? yes/no"
$ipsetQ = Read-Host -Prompt "Do you wish to setup networking? If you choose yes, you will be asked more questions later! yes/no"
$InstallRolesQ = Read-Host -Prompt "Do you wish to install Server Roles Active Directory Domain Services and DNS Services? yes/no"
$LocalAdminQ = Read-Host -Prompt "Do you want to create a new Local Admin user :Admin: with password: LocAdm800! ? "

# Local Admin add win srvr 2022, IoT win 10
#
#

function CreateLocalAdmin {
				if ($LocalAdminQ -eq "y" -OR $LocalAdminQ -eq "yes")
				{
		Write-Host " "
		Write-Host " Setting up local administrator user == Admin " -ForegroundColor Yellow
		Write-Host " "

		net user Admin p@ssw0rd! /ADD /PASSWORDCHG:NO
		WMIC useraccount WHERE "Name='Admin'" SET PasswordExpires=FALSE
		net localgroup administrators Admin /add
		net localgroup Users Admin /DELETE

		Write-Host " "
		Write-Host " =============================================== "
		Write-Host "User Admin added to Local Administrators with password (insecure)"  -ForegroundColor Green
		Write-Host " "
		}
}

CreateLocalAdmin

# Time Zone setting
#
# with a menu for 3 timezones
function TimezoneSet {
	$TimeZnQ = Read-Host -Prompt " Do you want to set a timezone? yes/no"
		if ($TimeZnQ -eq "yes" -OR $TimeZnQ -eq "y")
	{ 
	Write-Host " Choose a Timezone : " -ForegroundColor Yellow
	Write-Host " 1. UTC/GMT "
	Write-Host " 2. GTB (Athens) "
	Write-Host " 3. Central Europe Standard Time (CET/CEST; Prague, Berlin) " 

	$choiceTimezone = Read-Host " Enter your choice (1, 2 or 3) "

	switch ($choiceTimezone) {
		"1" {
			Write-Host " Setting time to GMT " -ForegroundColor Yellow
			# Insert code for Option 1 here
			tzutil /s "UTC"
			Write-Host " "
			Write-Host " =============================================== "
			Write-Host " Time-Zone set to UTC/GMT " -ForegroundColor Green
			Write-Host " "
		}
		"2" {
			Write-Host " Setting time to GBT " -ForegroundColor Yellow
			# Insert code for Option 2 here
			Write-Host " "
			Write-Host " =============================================== "
			Write-Host " Time-Zone set to GTB Standard Time " -ForegroundColor Green
			Write-Host " "
		}
		"3" {
			Write-Host " Setting time to CET/CEST " -ForegroundColor Yellow
			# Insert code for Option 3 here
			Write-Host " "
			Write-Host " =============================================== "
			Write-Host " Time-Zone set to GTB Standard Time " -ForegroundColor Green
			Write-Host " "
		}	
		Default {
			Write-Host "Invalid choice. Please select 1, 2 or 3."
		}
	}
	}
}

TimezoneSet



# Disable Server Manager startup 
# located in scheduled Tasks
# 2023/3 payomagic

function Disable-ServerManagerAutostart {
	Write-Host " "
	Write-Host " === The Server Manager is going to be disabled == " -ForegroundColor Yellow
	Write-Host " "

	Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

	Write-Host " "
	Write-Host " =============================================== "
	Write-Host " The Server Manager had been disabled " -ForegroundColor Green
	Write-Host " "
}

Disable-ServerManagerAutostart




# Enable RDP and firewall rule
#
#
function RDP-Enable {
	Write-Host " " 
	Write-Host " == Enabling the RDP access == " -ForegroundColor Yellow
	Write-Host " "

	Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Verbose
	Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose

	#other possibillity: made by Litto
	#reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
	#netsh advfirewall firewall set rule group="remote desktop" new enable=yes

	Write-Host " "
	Write-Host " =============================================== "
	Write-Host " The RDP had been enabled! " -ForegroundColor Green
	Write-Host " "
}

RDP-Enable




# Disable MS IE Enhanced Security
# 2023/03 payomagic
#
function Disable-MSIEESC {
	# set vars in registry
	$AdminKey= "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
	$UserKey= "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
	 
	Write-Host " "
	Write-Host "::The registry key for MS IE Enhanced Security found::" -ForegroundColor Yellow
	Write-Host " "
	Get-ItemProperty -Path $AdminKey -Name "IsInstalled"
	Get-ItemProperty -Path $UserKey -Name "IsInstalled"

	Write-Host " "
	Write-Host "::Disabling the Enhanced Security of Internet Explorer::" -ForegroundColor Yellow
	Write-Host " "

	# disable ESC    
	Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force -Verbose
	Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force -Verbose

	Stop-Process -Name Explorer

	Write-Host " =============================================== "
	Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
	Write-Host " "
}

Disable-MSIEESC



# Disable NETBIOS with prompt 
#
# 2023

function Disable-NETBIOS {
		if($netbdisQ -eq "y" -OR $netbdisQ -eq "yes")
				{
				# vars in registry
				$base="HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"

				# get the interfaces name in registry
				$RegistryInterfaces=Get-ChildItem "$base"|Select -ExpandProperty PSChildName

				Write-Host " "
				Write-Host " Interfaces found : " -ForegroundColor Yellow
				Write-Host " "
				$RegistryInterfaces 
				#Get-ChildItem "$base"|Select -ExpandProperty PSChildName
				Write-Host " "
				Write-Host " Disabling NETBIOS... " -ForegroundColor Yellow
				Write-Host " "

				# set value 2 on each interface found
					foreach($RegistryInterface in $RegistryInterfaces) {
					Set-ItemProperty -Path "$base\$RegistryInterface" -Name "NetbiosOptions" -Value 2 -verbose
					}

				Write-Host " "
				Write-Host " ========================================= "
				Write-Host "NETBIOS had been disabled on network adapters." -ForegroundColor Green
				Write-Host " "
				}
}

Disable-NETBIOS






# Disable ISATAP (IPv6) on network adapter
#
# 

function Disable-ISATAP {
		if($disISATAPQ -eq "y" -OR $disISATAPQ -eq "yes")
			{
				Write-Host " "
				Write-Host " IPv6 ISATAP and 4to6 tunelling to be disabled ... "

				# list interfaces with IPv6
				Write-Host " "
				Write-Host " Interfaces where IPv6 can be set :" -ForegroundColor Yellow
				Write-Host " "
				
        Get-NetAdapterBinding|Where-Object ComponentID -eq "ms_tcpip6"

				Write-Host " "
				Write-Host " "
				Write-Host "Disabling IPv6 on all interfaces..." -ForegroundColor Yellow
				Write-Host "..."

				# disable ISATAP and IPv6 tunnelling 
				Disable-NetAdapterBinding -Name "*" -ComponentID "ms_tcpip6" -verbose
				netsh interface teredo set state disabled 
				netsh interface 6to4 set state disabled undoonstop=disabled 
				netsh interface isatap set state disabled
				
				Write-Host " "
				Write-Host " Verifying... "
				Write-Host " "
				
        netsh interface isatap show state

				Write-Host " "
				Write-Host " ========================================= "
				Write-Host "ISATAP had been disabled on all network adapters." -ForegroundColor Green
				Write-Host " "
			}
}

Disable-ISATAP







# File and Printer Sharing options
# from Litto
#

function Enable-PrintSharingDiscoverOpt {
	Write-Host " File and Printer Sharing to be enabled... "	
	Set-Service FDResPub -startuptype "Automatic"
	Set-Service upnphost -startuptype "Automatic"
	Set-Service dnscache -startuptype "Automatic"
	Set-Service SSDPSRV -startuptype "Automatic"
	Start-Service -name FDResPub, upnphost, dnscache, SSDPSRV

	netsh advfirewall firewall set rule group=”Network discovery” new enable=yes > $null
	netsh advfirewall firewall set rule group="File and Printer sharing" new enable=yes > $null
	
	Write-Host " "
	#Write-Host " In case of error - start powershell as administrator! "
	Write-Host " =============================================== "
	Write-Host "File and Printer Sharing Enabled." -Foreground Green
	Write-Host "Network Discovery Enabled." -Foreground Green
	Write-Host " "
}

Enable-PrintSharingDiscoverOpt





# Adding Firewall rules
# by Litto / for * project
#

function Enable-FWSomeHosts {
	if($Host_Name -eq "APPP1025")
		{
			Write-Host " "
			Write-Host " Setting up firewall rules ..." -ForegroundColor Yellow
			Write-Host " "
			New-NetFirewallRule -DisplayName '_Allow McAfee Agent communication' -Profile @('Domain', 'Private', 'Public') -Direction Inbound  -Protocol TCP -LocalPort 6543 -Action Allow
			#
			Write-Host " "
			Write-Host " ================================================== "
			Write-Host " Firewalls rules for McAfee Agent comms had been allowed " -ForegroundColor Green
			Write-Host " "

		}
	elseif($Host_Name -eq ("NOC2021" -or "NOC2022"))
		{
			Write-Host " "
			Write-Host " Setting up firewall rules ..." -ForegroundColor Yellow
			Write-Host " "
			New-NetFirewallRule -DisplayName '_Allow NTP communication' -Profile @('Domain', 'Private', 'Public') -Direction Inbound -Protocol UDP -LocalPort 123 -Action Allow
			Write-Host " "
			Write-Host " ================================================== "
			Write-Host " Firewalls rules for NTP port 123 allowed " -ForegroundColor Green
			Write-Host " "
		}
}

Enable-FWSomeHosts






#=======================================================================================================================================================
# Network & IP address setting
# with prompt
# orig by Litto , tuned up by payomagic 2023
#

function IPNetworkSetup {
  
  if ($ipsetQ -eq "y" -OR $ipsetQ -eq "yes"){
  
  Write-Host " "
  Write-Host " Now setting up IP addresses for * environment... " -ForegroundColor Yellow
  Write-Host " "
  
  Write-Host " How do you want to set IP addresses, mask, gateway and DNS : "
  Write-Host " 1. Manually - provide new interface name, IP address, mask, gateway and DNS "
  Write-Host " 2. as per pre-defined template (*) "
  Write-Host " 3. with a CSV "

	$choiceNetwork = Read-Host " Enter your choice ( 1, 2 or 3 ) "

	switch ($choiceNetwork) {
	"1" {
        $ManAdapters = Get-NetAdapter | Select Name

		Write-Host " "
		Write-Host " We found the following adapters on the host : " -ForegroundColor Yellow
		Write-Host " "
		$ManAdapters
		
		Write-Host " "
		Write-Host " Answer the following questions to set IP addresses manually " -ForegroundColor Yellow
     
		foreach($ManAdapter in $ManAdapters) {
			$ManAdapterName = $ManAdapter.Name
			$ManNewName = Read-Host -Prompt " Provide a new interface name for '$ManAdapterName' : "
			$ManIPSet = Read-Host -Prompt " Provide an IP address on network adapter '$ManAdapterName' : "
			$ManMaskSet = Read-Host -Prompt " Provide a mask on network adapter '$ManAdapterName' (x.x.x.x format) : "
			$ManGatewaySet = Read-Host -Prompt " Provide a default gateway IP for '$ManAdapterName' : "
			$ManDNSSet = Read-Host -Prompt " Provide a primary DNS server for '$ManAdapterName' : "
			
			if ($ManAdapter) {
				Rename-NetAdapter -Name $ManAdapterName -NewName $ManNewName
				Write-Host " "
				Write-Host "Renamed adapter '$ManAdapterName' to '$ManNewName'" -ForegroundColor Green
				Write-Host " "
			} else {
				Write-Host " ERROR : No interface '$ManAdapterName' found ! " -ForegroundColor Red
				}
			
			$ManNewInt = Get-NetAdapter -Name "$ManNewName"
			
			if ($ManNewInt) {
			netsh interface ipv4 set address name="$ManNewName" static $ManIPSet $ManMaskSet $ManGatewaySet	
		# IP, Mask, GTW address set
			netsh interface ipv4 set dnsservers name="$ManNewName" static $ManDNSSet primary validate=no
		# Primary DNS
			
			Write-Host " Interface setup done. Interface '$ManAdapterName' renamed to '$ManNewName'. IP Address set to '$ManIPSet', Mask '$ManMaskSet', Gateway '$ManGatewaySet' and DNS set to '$ManDNSSet' "
			} else {
				Write-Host " ERROR : No interface '$ManNewName' found ! " -ForegroundColor Red
				}
		}
	
	Write-Host " "
	Write-Host " =================================== "
	Write-Host " Manual network setup had been done... Exiting." -ForegroundColor Green
} 
#End of choice 1 = manual network setup

"2" {
Write-Host " Omitted / in personal repo "
}


	"3" {
        Write-Host " Setting up with CSV "
        # Path to file to be be chosen
		# Load the CSV file containing the adapter names, new names, IP addresses, subnet masks, default gateways, and DNS servers
		# CSV file has a header row with the column names "OldName", "NewName", "IPAddress", "SubnetMask", "DefaultGateway", and "DNSServer"
		
		$file = Read-Host -Prompt " Please provide a full path to CSV file "
		$adapters = Import-Csv -Path $file -Delimiter ';'

		Write-Host " "
		Write-Host " Checking if adapters existing..." -ForegroundColor Yellow
		Write-Host " "

		# Loop through each adapter and rename it, set its IP address, subnet mask, default gateway, and DNS server
		foreach ($adapter in $adapters) {
			$CSVoldName = $adapter.OldName
			$CSVnewName = $adapter.NewName
			$CSVipAddress = $adapter.IPAddress
			$CSVsubnetMask = $adapter.SubnetMask
			$CSVDefaultGW = $adapter.DefaultGateway
			$CSVDNSServer = $adapter.DNSServer

			$networkAdapter = Get-NetAdapter -Name $CSVoldName
			if ($networkAdapter) {
				Rename-NetAdapter -Name $CSVoldName -NewName $CSVnewName
				Write-Host " "
				Write-Host "Renamed adapter '$CSVoldName' to '$CSVnewName'" -ForegroundColor Green
				Write-Host " "

				# Set the adapter's IP address, subnet mask, default gateway, and DNS server
				$adapterConfig = Get-NetAdapterAdvancedProperty -Name $CSVnewName -RegistryKeyword NetworkAddress
				Write-Host " "
				Write-Host " Checking if Advanced Property NetworkAddress exists..." -ForegroundColor Yellow
				Write-Host " "
					if ($adapterConfig) {
						netsh interface ipv4 set address name="$CSVnewName" static $CSVipAddress $CSVsubnetMask $CSVDefaultGW
						# IP, Mask, GTW address set
						netsh interface ipv4 set dnsservers name="$CSVnewName" static $CSVDNSServer primary validate=no
						# Primary DNS
						Write-Host " "
						Write-Host "Set IP address '$CSVipAddress', subnet mask '$CSVsubnetMask', default gateway '$CSVDefaultGW', and DNS server '$CSVDNSServer' for adapter '$CSVnewName'" -ForegroundColor Green
						Write-Host " "
					}
					else {
					Write-Host "Could not find registry key for Network Address on adapter '$CSVnewName'" -ForegroundColor Red
				}
			}
			else {
				Write-Host "Could not find adapter '$CSVoldName'" -ForegroundColor Red
			}
		}
	}

Default {
			Write-Host "Invalid choice. Please select 1, 2 or 3."
		  }
    }		
  }
}

IPNetworkSetup







# Hostname setting
#
#

function HostnameSet {
		
    $Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-ExecutionPolicy Bypass -File "C:\Temp\server-deploy-step2.ps1"'
		$Trigger = New-ScheduledTaskTrigger -AtLogon
		$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
		$Principal = New-ScheduledTaskPrincipal -UserID "Administrator" -LogonType Interactive -RunLevel Highest
		$Task = Register-ScheduledTask -TaskName "ContinueInstall" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal
		$Task
	
	Rename-Computer -NewName $Host_Name

	Write-Host " "
	Write-Host " =============================================== "
	Write-Host " New hostname set to '$Host_Name'. Restarting to apply changes. Install will continue after reboot.. " -ForegroundColor Green
	Write-Host "Log in as Administrator! " -ForegroundColor Red
	Write-Host " "

	pause
	
	Restart-Computer
	
}

HostnameSet
