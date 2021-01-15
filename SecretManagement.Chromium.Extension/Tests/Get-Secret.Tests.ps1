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
        $fetchedSecret = SecretManagement.Chromium.Extension\Get-Secret @defaultVaultParams -Name 'pester@twitter.com' 
        $fetchedSecret | Should -BeOfType 'PSCredential'
        $fetchedSecret.GetNetworkCredential().Password | Should -Be 'pasterpassword'
        $fetchedSecret.UserName | Should -Be 'pester'
    }
}