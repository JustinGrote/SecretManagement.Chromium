#requires -modules @{ModuleName="Pester"; ModuleVersion="5.1.0"}
Describe 'Test-SecretVault' {
    BeforeEach {
        . $PSScriptRoot/Shared.ps1
        PrepareTestEnvironment
    }
    AfterEach {
        TeardownTestEnvironment
    }

    It 'Successfully Tests Mock Database' {
        SecretManagement.Chromium.Extension\Test-SecretVault @DefaultVaultParams |
            Should -Be $true
    }

    It 'Fails for wrong path' -Tag 'File' {
        $vaultParams = New-DeepCopyObject $defaultVaultParams
        $vaultParams.AdditionalParameters.DataPath = 'C:\fake'
        { SecretManagement.Chromium.Extension\Test-SecretVault @VaultParams } |
            Should -Throw '*because it does not exist.'
    }

    It 'Fails for invalid database file' -Tag 'Chromium' {
        $vaultParams = New-DeepCopyObject $defaultVaultParams
        #Create a random empty file
        $vaultParams.AdditionalParameters.DataPath = New-Item -ItemType File -Path "$TestDrive/InvalidDatabaseFile"

        { SecretManagement.Chromium.Extension\Test-SecretVault @VaultParams } |
            Should -Throw '*is not a valid Chromium password database (Logins table not found)'
    }

    It 'Closes the vault safely' -Tag 'File','Chromium' {
        SecretManagement.Chromium.Extension\Test-SecretVault @DefaultVaultParams
        Remove-Item $DefaultVaultParams.AdditionalParameters.DataPath -ErrorAction Stop
    }
}