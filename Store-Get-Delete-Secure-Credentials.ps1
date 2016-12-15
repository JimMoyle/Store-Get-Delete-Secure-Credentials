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

$OrgName = Read-Host "Enter Organization or Application Name"
$OrgName = $OrgName.Replace(" ", "")
Write-Verbose "Storing $OrgName"

If (-not (Test-Path "HKCU:\Software\$OrgName\Credentials"))
{
	Try
	{
		Write-Verbose "Credentials Path Not Found. Trying to create Key HKCU:\Software\$OrgName"
		New-Item -Path "HKCU:\Software\$OrgName" -Name "Credentials" -Force -ErrorAction Stop
		Write-Verbose "Created Key HKCU:\Software\$OrgName"
	}
	Catch
	{
		Write-Error "Unable to create path. Exiting script"
	}
}

$secureCredential = Get-Credential -Message "Enter service account credential in DOMAIN\Username or Username@Domain.com format."
$credentialName = Read-Host "Enter a name for this credential"
$securePasswordString = $secureCredential.Password | ConvertFrom-SecureString
$userNameString = $secureCredential.Username

$regpath = "HKCU:\Software\$OrgName\Credentials\$credentialName"

Write-Verbose "Storing credential $usernameString under $regpath."

try
{
	New-Item -Path $regpath -ErrorAction Stop
	
	$params = @{
		'Path' = $regpath
		'PropertyType' = 'String'
		'ErrorAction' = 'Stop'
	}
	
	New-ItemProperty @params -Name UserName -Value $userNameString
	New-ItemProperty @params -Name Password -Value $securePasswordString
}
catch
{
	Write-Error "Could not create Credential in specified path"
}

<#
To retrieve this credential, you must be logged in as the current user and copy/paste this 
into the credential area of your PowerShell script, referencing your credential as" '$credential'":"

$secureCredUserName = Get-ItemProperty -Path HKCU:\Software\$OrgName\Credentials\$credentialName -Name UserName"
$secureCredPassword = Get-ItemProperty -Path HKCU:\Software\$OrgName\Credentials\$credentialName -Name Password"
$securePassword = ConvertTo-SecureString $secureCredPassword
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $secureCredUserName, $securePassword
#>