<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.3.131
	 Created on:   	17/12/2016 13:07
	 Created by:   	testuser
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

Get-SecureCredential

Add-SecureCredential -Name One -Username testuser -PlainTextPassword password

Add-SecureCredential Two testuser password

Add-SecureCredential -Name Three -Username testuser -PlainTextPassword password

$pass = 'password' | ConvertTo-SecureString -AsPlainText -Force

Add-SecureCredential -Name Four -Username testuser -Password $pass

$testuser = Get-Credential

$testuser | Add-SecureCredential -Name Five

Get-SecureCredential

Get-SecureCredential -Name Two

Get-SecureCredential Three

Remove-SecureCredential -Name One

Remove-SecureCredential Two

Remove-SecureCredential Three

Get-SecureCredential | Remove-SecureCredential