#requires -modules @{ModuleName="Pester"; ModuleVersion="5.1.0"}
Describe 'Get-Secret' {
    BeforeEach {
        . $PSScriptRoot/Shared.ps1
        PrepareTestEnvironment
        Register-SecretVault @registerVaultParams
    }
    AfterEach {
        TeardownTestEnvironment
        $testVault | Microsoft.Powershell.SecretManagement\Unregister-SecretVault -ErrorAction SilentlyContinue
    }

    It 'Fetches Secret By Name' {
        $fetchedSecret = SecretManagement.Chromium.Extension\Get-Secret @defaultVaultParams -Name 'pester2|https://twitter.com/' 
        $fetchedSecret | Should -BeOfType 'PSCredential'
        $fetchedSecret.GetNetworkCredential().Password | Should -Be 'pasterpassword'
        $fetchedSecret.UserName | Should -Be 'pester2'
    }
    It 'Returns null on invalid name' {
        SecretManagement.Chromium.Extension\Get-Secret @defaultVaultParams -Name 'PESTERMISSINGNAME' | 
            Should -BeNullOrEmpty
    }
    It 'Fails on ambiguous match' {
        {SecretManagement.Chromium.Extension\Get-Secret @defaultVaultParams -Name '*twitter*'} |
            Should -Throw 'Your secret search is ambiguous*'
    }
    It 'Fails on null Name' {
        {SecretManagement.Chromium.Extension\Get-Secret @defaultVaultParams -Name $null} |
            Should -Throw 'You must specify a specific secret*'
    }
}