# Create a .(root) DNS zone to prevent external name resolution
function CreateRootDNSZone {
	
	$RootDNSZoneQ = Read-Host -Prompt " Do you want to create a .(Root) DNS Zone? yes/no "
		
		if ($RootDNSZoneQ -eq "y" -OR $RootDNSZoneQ -eq "yes")
		{
		Write-Host " "
		Write-Host " Creating a .(root) DNS zone... " 
		Write-Host " "
		
		Add-DnsServerPrimaryZone -Name "." -ZoneFile "root.dns" -DynamicUpdate None
		
		} 
}

CreateRootDNSZone

# some of the functions omitted due privacy
function NewAdminCreate {
	
	$AdminCreateQ = Read-Host -Prompt "Do you want to create a new Admin user as a copy of Administrator with Domain Admin? yes/no"
	
	if ($AdminCreateQ -eq "y" -OR $AdminCreateQ -eq "yes")
	{
	Write-Host " "
	Write-Host " Creating new Admin user... " -ForegroundColor Yellow
	Write-Host " "
	$newAdminPassword = Read-Host -Prompt "Provide Admin password : "
	$passwordAdmin = ConvertTo-SecureString $newAdminPassword -AsPlainText -Force
	$forestPath = (Get-ADDomain).Forest
	
	New-ADUser -Name "Admin" -SAMAccountName Admin -GivenName Admin -UserPrincipalName Admin@$forestPath -Instance Administrator -ChangePasswordAtLogon $false -Enabled $true -PasswordNeverExpires $true -AccountPassword $passwordAdmin
	Add-ADGroupMember -Identity "Schema Admins" -Members Admin
	Add-ADGroupMember -Identity "Domain Admins" -Members Admin
	Add-ADGroupMember -Identity "Enterprise Admins" -Members Admin
	Add-ADGroupMember -Identity "Administrators" -Members Admin
	Add-ADGroupMember -Identity "Group Policy Creator Owners" -Members Admin
	Add-ADGroupMember -Identity "Remote Desktop Users" -Members Admin
	Add-ADGroupMember -Identity "IndustrialITAdmin" -Members Admin
	Add-ADGroupMember -Identity "IndustrialITUser" -Members Admin
	Remove-ADGroupMember -Identity "Domain Users" -Member Admin
	
	Write-Host " "
	Write-Host " New user Admin created " -ForegroundColor Green
	Write-Host " "
	}
}

function NPTUsersCreate {
	
	$NPTUsersQ = Read-Host -Prompt "Do you want to create Install and Service users and add them to correct groups (for NPT?) yes/no"
		
	if ($NPTUsersQ -eq "y" -OR $NPTUsersQ -eq "yes")
	{
	Write-Host " Creating user Install... " -ForegroundColor Yellow
	
	$newInstallPassword = Read-Host -Prompt "Provide new Install password : "
	$passwordInstall = ConvertTo-SecureString $newInstallPassword -AsPlainText -Force
	
	New-ADUser -Name "Install" -SAMAccountName Install -GivenName Install -UserPrincipalName Install@$forestPath -Instance Administrator -ChangePasswordAtLogon $false -Enabled $true -PasswordNeverExpires $true -AccountPassword $passwordInstall
	
	Add-ADGroupMember -Identity "Administrators" -Members Install
	Add-ADGroupMember -Identity "IndustrialITAdmin" -Members Install
	Add-ADGroupMember -Identity "IndustrialITUser" -Members Install
	Add-ADGroupMember -Identity "Schema Admins" -Members Install
	Add-ADGroupMember -Identity "Domain Admins" -Members Install
	Add-ADGroupMember -Identity "Enterprise Admins" -Members Install
	Add-ADGroupMember -Identity "Group Policy Creator Owners" -Members Install
	Add-ADGroupMember -Identity "Remote Desktop Users" -Members Install
	Remove-ADGroupMember -Identity "Domain Users" -Member Install	
	
	Write-Host " Creating user Service... " -ForegroundColor Yellow
	
	$newServicePassword = Read-Host -Prompt "Provide new Service password : "
	$passwordService = ConvertTo-SecureString $newServicePassword -AsPlainText -Force
	
	New-ADUser -Name "Service" -SAMAccountName Service -GivenName Service -UserPrincipalName Service@$forestPath -Instance Administrator -ChangePasswordAtLogon $false -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true -AccountPassword $passwordService
	
	Add-ADGroupMember -Identity "Administrators" -Members Service
	Add-ADGroupMember -Identity "IndustrialITAdmin" -Members Service
	Add-ADGroupMember -Identity "IndustrialITUser" -Members Service
	Add-ADGroupMember -Identity "Schema Admins" -Members Service
	Add-ADGroupMember -Identity "Domain Admins" -Members Service
	Add-ADGroupMember -Identity "Enterprise Admins" -Members Service
	Add-ADGroupMember -Identity "Group Policy Creator Owners" -Members Service
	Remove-ADGroupMember -Identity "Domain Users" -Member Service
	
	Write-Host " "
	Write-Host " The NPT users Install and Service were created! " -ForegroundColor Green
	Write-Host " "	

	} else {
		Write-Host " No  users for Node Preparation Tool created! " -ForegroundColor Red
		}
}


function NPTOUGroupsCreate {
	
	$NPTOUGroupsQ = Read-Host -Prompt "Do you want to create OU and Groups needed for  Node Preparation Tool (NPT) ? "
		
	if ($NPTOUGroupsQ -eq "y" -OR $NPTOUGroupsQ -eq "yes")
	{
	$ADDinstingName = (Get-ADDomain).DistinguishedName
	New-ADOrganizationalUnit -Name "TestIT" -Path "$ADDinstingName"
	New-ADOrganizationalUnit -Name "TestITUsers" -Path "OU=TestIT,$ADDinstingName"
	New-ADOrganizationalUnit -Name "TestITComputers" -Path "OU=TestIT,$ADDinstingName"
	New-ADGroup -Name "TestAdmin" -Path "OU=TestITUsers,OU=TestIT,$ADDinstingName" -GroupScope Global
	New-ADGroup -Name "TestUser" -Path "OU=TestITUsers,OU=TestIT,$ADDinstingName" -GroupScope Global
	
	} else {
			Write-Host " No Organizational Units and Groups for NPT created! "
		}
}


NPTOUGroupsCreate
NPTUsersCreate
NewAdminCreate

#Delete the scheduled task from previous script 
Write-Host " "
Write-Host " Removing the scheduled task..."
Write-Host " "

Unregister-ScheduledTask -TaskName "CreateOUandGroups" -Confirm:$false

Write-Host " Server deployment with pre-requisites done. "


pause
