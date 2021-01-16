#requires -modules @{ModuleName="Pester"; ModuleVersion="5.1.0"}
Describe 'Register-ChromiumSecretVault' {
    BeforeAll {
        Import-Module $PSScriptRoot/.. -Force -Verbose
    }
    AfterAll {
        Remove-Module SecretManagement.Chromium -Force
    }

    It 'Registers Chrome Preset Vault' {
        Register-ChromiumSecretVault -Preset Chrome
    }
    It 'Registers Chrome Preset Vault w/ AllowClobber' {
        Get-SecretVault 'Chrome-Default' -ErrorAction SilentlyContinue | Unregister-SecretVault -ErrorAction SilentlyContinue
        if (Get-SecretVault 'Chrome-Default' -ErrorAction SilentlyContinue) {throw 'Cannot proceed because a vault with same name could not be cleaned up'}
        Register-ChromiumSecretVault -Preset Chrome
        Register-ChromiumSecretVault -Preset Chrome -AllowClobber
        $chromeVault = Get-SecretVault 'Chrome-Default'
        $chromeVault.VaultParameters.DataPath | Should -Exist
        $chromeVault.VaultParameters.StatePath | Should -Exist
        $chromeVault.Name | Should -Be 'Chrome-Default'
    }
    It 'Registers All Vaults' {
        Register-ChromiumSecretVault -WarningAction SilentlyContinue
        Register-ChromiumSecretVault -AllowClobber
    }
}