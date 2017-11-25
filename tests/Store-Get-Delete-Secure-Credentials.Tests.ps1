
<#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
#>

Import-Module -Force $PSScriptRoot\..\Store-Get-Delete-Secure-Credentials.ps1

$existing = 0
$user1 = 'Test1'
$pass1 = 'password1'
$user2 = 'Test2'
$pass2 = 'password2'
$user3 = 'Test3'
$pass3 = 'password3'

Describe 'Add-SecureCredential' {

    It "Adds plain text password creds" {
        Add-SecureCredential -Name One -Username $user1 -PlainTextPassword $pass1 | Should Be $null
    }

    It "Adds secure password creds" {
        $pass = $pass2 | ConvertTo-SecureString -AsPlainText -Force
        Add-SecureCredential -Name Two -Username $user2 -Password $pass | Should Be $null
    }

    It 'Adds credentials through pipeline'{
        $username = $user3
        $pass = $pass3 | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $pass
        $cred | Add-SecureCredential -name Three | Should Be $null
    }
}

Describe 'Get-SecureCredential'{

    It 'Gets All Credentials'{
        $result = Get-SecureCredential
        $result.count | Should Be ($existing + 3)
    }

    It 'Gets First UserName'{
        $result1 = Get-SecureCredential -Name One
        $result1.UserName | Should Be $user1
    }

    It 'Gets Second UserName'{
        $result2 = Get-SecureCredential -Name Two
        $result2.UserName | Should Be $user2
    }

    It 'Gets Third UserName'{
        $result3 = Get-SecureCredential -Name Three
        $result3.UserName | Should Be $user3
    }

    It 'Gets First Password' {
        $result1 = Get-SecureCredential -Name One
        $result1.GetNetworkCredential().password | Should Be $pass1
    }

    It 'Gets Second Password' {
        $result2 = Get-SecureCredential -Name Two
        $result2.GetNetworkCredential().password | Should Be $pass2
    }

    It 'Gets Third Password' {
        $result3 = Get-SecureCredential -Name Three
        $result3.GetNetworkCredential().password | Should Be $pass3
    }
}

Describe 'Remove-SecureCredential'{

    It 'Removes First Cred' {
        Remove-SecureCredential -Name One | Should Be $null
    }

    It 'Removes Second Cred' {
        Remove-SecureCredential -Name Two | Should Be $null
    }

    It 'Removes All Creds' {
        Get-SecureCredential | Remove-SecureCredential | Should Be $null
    }
    It 'Checks that none are left' {
        $result = Get-SecureCredential
        $result.count | Should Be ($existing)
    }
}