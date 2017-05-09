<#
	.NOTES
	===========================================================================
	 Created on:   	15/12/2016 13:43
	 Created by:   	Jim Moyle
	 Github: https://github.com/JimMoyle/Store-Get-Delete-Secure-Credentials
	 Twitter: @jimmoyle
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
<#
	.SYNOPSIS
		Store credentials securely in the registry

	.DESCRIPTION

		To retrieve this credential, you must be logged in as the current user and use Get-SecureCredential

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
			Mandatory = $true

		)]
		[System.String]$Username,

		[Parameter(
			Position = 2,
			ValuefromPipelineByPropertyName = $true,
			ParameterSetName = "PlainText",
			Mandatory = $true
		)]
		[System.String]$PlainTextPassword,

		[Parameter(
				   Position = 2,
				   ValuefromPipelineByPropertyName = $true,
				   ParameterSetName = "SecureString",
				   Mandatory = $true
		)]
		[System.Security.SecureString]$Password
	)


	BEGIN {
	}

	PROCESS {

		$pathRoot = "HKCU:\Software\SecureCredentials"

		if (-not (Test-Path -Path $pathRoot))
		{
			New-Item -Path $pathRoot -ErrorAction Stop | Out-Null
		}

		switch ($PsCmdlet.ParameterSetName)
		{
			'SecureString' {
				$securePasswordString = $Password | ConvertFrom-SecureString
				break
			}
			'PlainText' {
				$securePasswordString = $PlainTextPassword | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
				break
			}

		}

		$userNameString = $Username

		$credPath = "$pathRoot\$Name"

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
			Write-Error "Could not create Credential in $credPath."
		}

	}
	END {
	}
}
<#
	.SYNOPSIS
		Gets credentials already stored in the local registry under the local users account
#>
function Get-SecureCredential
{
	[CmdletBinding()]
	param(
		[Parameter(
			Position = 0,
			ValuefromPipelineByPropertyName = $true,
			ValuefromPipeline = $true
		)]
		[System.String]$Name
	)


	BEGIN {
	}

	PROCESS
	{

		$pathRoot = 'HKCU:\Software\SecureCredentials'

		if ($Name)
		{

			if (-not (Test-Path -Path $pathRoot\$Name))
			{
				Write-Error "Credentials cannot be found at $pathRoot\$Name"
			}

			$secureCredUserName = Get-ItemProperty -Path $pathRoot\$Name | Select-Object -ExpandProperty UserName
			$secureCredPassword = Get-ItemProperty -Path $pathRoot\$Name | Select-Object -ExpandProperty Password
			$securePassword = ConvertTo-SecureString $secureCredPassword
			$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $secureCredUserName, $securePassword

			Write-Output $credential

		}
		else
		{
			if (Test-Path -Path $pathRoot){
				$list = Get-ChildItem $pathRoot | Select-Object @{ n = 'Name'; e = { $_.PSChildName } }
			}
			$credlist = @()

			foreach ($cred in $list.name)
			{
				$secureCredUserName = Get-ItemProperty -Path $pathRoot\$cred | Select-Object -ExpandProperty UserName
				$secureCredPassword = Get-ItemProperty -Path $pathRoot\$cred | Select-Object -ExpandProperty Password
				$securePassword = ConvertTo-SecureString $secureCredPassword
				$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $secureCredUserName, $securePassword

				$credWithName = $credential | Select-Object -Property @{ n = 'Name';  e= { $cred } }, UserName, Password


				$credlist += $credWithName
			}

			Write-Output $credlist

		}

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
	[CmdletBinding()]

	param (
		[Parameter(
			Position = 0,
			ValuefromPipelineByPropertyName = $true,
			Mandatory = $true
		)]
		[System.String]$Name
	)

	BEGIN{
	}

	PROCESS
	{

		$pathRoot = 'HKCU:\Software\SecureCredentials'

		if (-not (Test-Path -Path $pathRoot\$Name))
		{
			Write-Error "$Name Credentials cannot be found at $pathRoot\$Name"
			break
		}

		Remove-Item -Path $pathRoot\$Name

	}

	END{
	}
}

#Add-SecureCredential Test Jim Moyle

Get-SecureCredential