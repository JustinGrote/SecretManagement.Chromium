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
        SecretManagement.Chromium.Extension\Get-Secret @defaultVaultParams -Name 'pester@twitter.com'
    }
}