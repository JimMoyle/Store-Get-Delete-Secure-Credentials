<#	
	.NOTES
	===========================================================================
	 Created on:   	15/12/2016 13:43
	 Created by:   	Jim Moyle
	 Github: https://github.com/JimMoyle/Hearthstone-Predictor
	 Twitter: @jimmoyle
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

<#
	.SYNOPSIS
		Store credentials securely in the registry

	.DESCRIPTION

		To retrieve this credential, you must be logged in as the current user and copy/paste this 
		into the credential area of your PowerShell script, referencing your credential as $credential 

		$secureCredUserName = Get-ItemProperty -Path HKCU:\Software\SecureCredentials\$appName\$credentialName | Select-Object -ExpandProperty UserName
		$secureCredPassword = Get-ItemProperty -Path HKCU:\Software\SecureCredentials\$appName\$credentialName | Select-Object -ExpandProperty Password
		$securePassword = ConvertTo-SecureString $secureCredPassword
		$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $secureCredUserName, $securePassword

		or use Get-SecureCredential

#>
function Add-SecureCredential
{
	[CmdletBinding()]
	param (
		
		[Parameter(
			Position = 0,
		 	ValuefromPipelineByPropertyName = $true,
			Mandatory = $true,
			HelpMessage = 'Type the name under which you wish to store these credentials'
		)]
		[System.String]$Name,
		
		[Parameter(
			Position = 1,
			ValuefromPipelineByPropertyName = $true,
			Mandatory = $false
		)]
		[System.String]$AppName,
		
		[Parameter(
			Position = 2,
			ValuefromPipelineByPropertyName = $true,
			ParameterSetName = "NoCredObject",
			Mandatory = $true
			
		)]
		[System.String]$Username,
		
		[Parameter(
			Position = 3,
			ValuefromPipelineByPropertyName = $true,
			ParameterSetName = "NoCredObject",
			Mandatory = $true
		)]
		[System.String]$Password,
		
		[Parameter(
				   Position = 4,
				   ValuefromPipelineByPropertyName = $true,
				   ValueFromPipeline = $true,
				   ParameterSetName = "CredObjectPresent"
		)]
		[System.Management.Automation.PSCredential]$Credential
	)
	
	
	BEGIN {
	}
	
	PROCESS {

		$pathRoot = "HKCU:\Software\SecureCredentials"
		
		#if appname not specified and there are apps already there give choice of existing apps
		if (-not ($AppName))
		{
			if (Test-Path $pathRoot)
			{
				
				$previousApps = (Get-ChildItem -Path $pathRoot).name
				
				if ($previousApps.count -gt 0)
				{
					$applist = @()
					foreach ($app in $previousApps)
					{
						$shortName = $app.split('\') | Select-Object -Last 1
						$applist += $shortName
					}
					$applist += 'Add new Application'
				}
				
				$startNumber = 1
				$number = $startNumber
				
				do
				{
					#give choice
					write-host ""
					
					foreach ($choice in $applist)
					{
						Write-Host "$number. $choice"
						
						$number++
					}
					
					Write-Host ""
					Write-Host -nonewline "Type your choice and press Enter: "
					$chosen = Read-Host
					Write-Host ""
					$ok = @($startNumber .. $number) -contains $chosen
					if (-not $ok)
					{
						Write-Host "Invalid selection"
					}
				}
				until ($ok)
				
				if ($number -eq $chosen)
				{
					Write-Host ""
					Write-Host -nonewline "Type your Application name and press Enter: "
					$AppName = Read-Host
				}
			} #if test path
			else
			{
				Write-Host ""
				Write-Host -nonewline "Type your Application name and press Enter: "
				$AppName = Read-Host
			}
		} #if not appname

				
		$appName = $appName.Replace(" ", "")
		Write-Verbose "Storing $appName"
		
		If (-not (Test-Path "$pathRoot\$appName"))
		{
			Try
			{
				Write-Verbose "Credentials Path Not Found. Trying to create Key $pathRoot\$appName"
				New-Item -Path $pathRoot -Name $appName -Force -ErrorAction Stop
				
				$appPath = "$pathRoot\$appName"
				
				Write-Verbose "Created Key $pathRoot\$appName"
			}
			Catch
			{
				Write-Error "Unable to create path in registry. Exiting script"
			}
		}
		
		switch ($PsCmdlet.ParameterSetName)
		{
			'CredObjectPresent' {
				$securePasswordString = $Credential.Password | ConvertFrom-SecureString
				$userNameString = $Credential.Username
				break
			}
			'NoCredObject' {
				$securePasswordString = $Password | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
				$userNameString = $Username
				break
			}
			
		}
		
		$credPath = "$appPath\$Name"
		
		Write-Verbose "Storing credential $usernameString under $credPath."
		
		try
		{
			New-Item -Path $credPath -ErrorAction Stop | Out-Null
			
			$params = @{
				'Path' = $credPath
				'PropertyType' = 'String'
				'ErrorAction' = 'Stop'
			}
			
			New-ItemProperty @params -Name UserName -Value $userNameString | Out-Null
			New-ItemProperty @params -Name Password -Value $securePasswordString | Out-Null
		}
		catch
		{
			Write-Error "Could not create Credential in specified path"
		}
		
	}
	END {
	}
}

<#
	.SYNOPSIS
		Gets credentials already stored in the local registry
#>
function Get-SecureCredential {
	[CmdletBinding()]
	param(
		[Parameter(
				   Position = 0,
				   ValuefromPipelineByPropertyName = $true
		)]
		[System.String]$Name,
		[Parameter(
				   Position = 1,
				   ValuefromPipelineByPropertyName = $true
		)]
		[System.String]$AppName
	)
	
	
	BEGIN {
	}
	
	PROCESS
	{
		
		$pathRoot = 'HKCU:\Software\SecureCredentials'
		
		if ($appname -eq '' -or $Name -eq '')
		{
			$allCreds = Get-ChildItem -Path $pathRoot -Recurse
			Write-Output $allCreds
			break
		}
		
		if (-not (Test-Path -Path $pathRoot\$AppName\$Name))
		{
			Write-Error "Credentials cannot be found at $pathRoot\$AppName\$Name"
		}
		
		$secureCredUserName = Get-ItemProperty -Path $pathRoot\$AppName\$Name | Select-Object -ExpandProperty UserName
		$secureCredPassword = Get-ItemProperty -Path $pathRoot\$AppName\$Name | Select-Object -ExpandProperty Password
		$securePassword = ConvertTo-SecureString $secureCredPassword
		$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $secureCredUserName, $securePassword
		
		Write-Output $credential

	}
	
	END {
	}
}

<#
	.SYNOPSIS
		Removes credentials from the local registry
#>
function Remove-SecureCredential
{
	[CmdletBinding(
		SupportsShouldProcess = $true,
		ConfirmImpact = "High"
	)]
	
	param (
		[Parameter(
			Position = 0,
			ValuefromPipelineByPropertyName = $true,
			Mandatory = $true
		)]
		[System.String]$Name,
		[Parameter(
			Position = 1,
			ValuefromPipelineByPropertyName = $true,
			Mandatory = $true
		)]
		[System.String]$AppName
	)
	
	BEGIN{
	}
	
	PROCESS
	{
		
		$pathRoot = 'HKCU:\Software\SecureCredentials'
		
		if (-not (Test-Path -Path $pathRoot\$AppName\$Name))
		{
			Write-Error "Credentials cannot be found at $pathRoot\$AppName\$Name"
			break
		}
		
		Remove-Item -Path $pathRoot\$AppName\$Name
		
	}
	
	END{
	}
}

Add-SecureCredential -Name Test01 -Username jimm@atlantiscomputing.com -Password blah