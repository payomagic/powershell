
$InstallRolesQ = Read-Host -Prompt "Do you wish to install Server Roles Active Directory Domain Services and DNS Services? yes/no"




#Delete the scheduled task from previous script 
Write-Host " "
Write-Host " Removing the scheduled task..."
Write-Host " "
Unregister-ScheduledTask -TaskName "ContinueInstall" -Confirm:$false





function NewForestInstall {
	
	$NewForestInstallQ = Read-Host -Prompt " Do you want to install new forest? yes/no "
	
	if ($NewForestInstallQ -eq "y" -OR $NewForestInstallQ -eq "yes")
		{
		$newDomainName = Read-Host -Prompt "Provide a new domain name : i.e. testsys.local "
		Write-Host " "
		Write-Host " New forest will be installed..."

#task to run at logon of Administrator
		
		Install-ADDSForest -DomainName $newDomainName -InstallDNS
		
		#restart!!!here!!!
		Write-Host " "
		Write-Host " Adding one-time task after restart to run at logon for Root DNS Zone config, OU and groups config (you will be asked after restart if you want to continue..." -ForegroundColor Yellow
		Write-Host " "
		
		$Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-ExecutionPolicy Bypass -File "C:\Temp\server-deploy-step3.ps1"'
		$Trigger = New-ScheduledTaskTrigger -AtLogon
		$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
		$Principal = New-ScheduledTaskPrincipal -UserID "Administrator" -LogonType Interactive -RunLevel Highest
		$Task = Register-ScheduledTask -TaskName "CreateOUandGroups" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal
		$Task
		
    Write-Host " Install will continue after restart... " -ForegroundColor Green
		

		Write-Host " "
		Write-Host " New forest '$newDomainName' created... Restart needed! " -ForegroundColor Green
		Write-Host " Install will continue after restart... " -ForegroundColor Green
		Write-Host " "		
		
    pause
    
    } else {
			$SecondaryControllerQ = -Prompt " Do you want to create a secondary domain controller? yes/no"
			if ($SecondaryControllerQ -eq "y" -OR $SecondaryControllerQ -eq "yes")
				{
				Write-Host " "
				Write-Host " Secondary Domain Controller will be installed. Please provide domain admin credentials and domain name when prompted : " -ForegroundColor Yellow
				Write-Host " "
		
				$SecondaryControllerDomainName = Read-Host -Prompt "Provide a domain name to add new controller into, i.e.: testsys.local "
				
				Install-ADDSDomainController -InstallDns -Credential (Get-Credential) -DomainName $SecondaryControllerDomainName
				
				Write-Host " "
				Write-Host "Secondary domain controller added to a domain '$SecondaryControllerDomainName'." -ForegroundColor Green
				Write-Host " "
				
				
				# Create a .(root) DNS zone to prevent external name resolution
				Add-DnsServerPrimaryZone -Name "." -ZoneFile "root.dns" -DynamicUpdate None
				
				}
			}
}







function InstallRoles-ADDS-DNS {
	if ($InstallRolesQ -eq "y" -OR $InstallRolesFeaturesQ -eq "yes")
	{ 
	Write-Host " "
	Write-Host " Installing Active Directory and DNS Server roles... " -ForegroundColor Yellow

	Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools

	Write-Host " "
	Write-Host " AD Domain Services and DNS Services installed! " -ForegroundColor Green
	Write-Host " "

  NewForestInstall

	}
}

InstallRoles-ADDS-DNS
