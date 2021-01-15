#requires -modules @{ModuleName="Pester"; ModuleVersion="5.1.0"}
Describe 'Test-SecretVault' {
    BeforeEach {
        . $PSScriptRoot/Shared.ps1
        PrepareTestEnvironment
    }
    AfterEach {
        TeardownTestEnvironment
    }

    It 'Succeeds by default' {
        SecretManagement.Chromium.Extension\Test-SecretVault @DefaultVaultParams
    }

    It 'Fails for wrong path' -Tag 'File' {
        $vaultParams = New-DeepCopyObject $defaultVaultParams
        $vaultParams.AdditionalParameters.Path = 'C:\fake'
        {SecretManagement.Chromium.Extension\Test-SecretVault @VaultParams} |
            Should -Throw '*because it does not exist.'
    }

    It 'Fails for invalid database' -Tag 'Chromium' {
        $vaultParams = New-DeepCopyObject $defaultVaultParams
        #Create a random empty file
        $vaultParams.AdditionalParameters.Path = [io.path]::GetTempFileName()
        {SecretManagement.Chromium.Extension\Test-SecretVault @VaultParams} |
            Should -Throw '*is not a valid Chromium password database (Logins table not found)'
    }

    It 'Closes the vault safely' -Tag 'File','Chromium' {
        SecretManagement.Chromium.Extension\Test-SecretVault @DefaultVaultParams
        Remove-Item $DefaultVaultParams.AdditionalParameters.Path -ErrorAction Stop
    }

    It 'Opens db even if DB already open' -Tag 'File','Chromium' {
        $SCRIPT:db = ReallySimpleDatabase\Get-Database $defaultVaultParams.AdditionalParameters.Path -WarningAction SilentlyContinue
        $db.open()
        SecretManagement.Chromium.Extension\Test-SecretVault @DefaultVaultParams -ErrorAction Stop
        $db.close()
    }
}