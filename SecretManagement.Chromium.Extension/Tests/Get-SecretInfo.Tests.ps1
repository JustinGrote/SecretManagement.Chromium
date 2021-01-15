#requires -modules @{ModuleName="Pester"; ModuleVersion="5.1.0"}
Describe 'Get-SecretInfo' {
    BeforeEach {
        . $PSScriptRoot/Shared.ps1
        PrepareTestEnvironment
        Register-SecretVault @registerVaultParams
    }
    AfterEach {
        TeardownTestEnvironment
        $testVault | Microsoft.Powershell.SecretManagement\Unregister-SecretVault -ErrorAction SilentlyContinue
    }
    It 'All secrets' {
        $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @defaultVaultParams
        $secretInfo | Should -HaveCount 4
    }

    It 'Secret by fully qualified name' {
        $secretName = 'pester@twitter.com'
        $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @defaultVaultParams -Filter $secretName
        $secretInfo | Should -HaveCount 1
        $secretInfo.Name | Should -Be $secretName
        $secretInfo.VaultName | Should -be '__PESTER'
        $secretInfo.Type | Should -Be 'PSCredential'
    }
    It 'Secret by username only' {
        $secretName = 'pester2'
        $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @defaultVaultParams -Filter $secretName
        $secretInfo | Should -HaveCount 1
        $secretInfo.Name | Should -Be 'pester2@twitter.com'
        $secretInfo.VaultName | Should -be '__PESTER'
        $secretInfo.Type | Should -Be 'PSCredential'
    }
    
    It 'Secret by domain only (multiple results)' {
        $secretName = '@twitter.com'
        $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @defaultVaultParams -Filter $secretName
        $secretInfo | Should -HaveCount 3
        'pester','pester2','pester3' | ForEach-Object {
            "$PSItem@twitter.com" | Should -BeIn $secretInfo.Name
        }
    }
}