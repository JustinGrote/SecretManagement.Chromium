@{
    ModuleVersion = '0.0.9.0'
    RootModule = 'SecretManagement.Chromium.Extension.psm1'
    FunctionsToExport = @('Set-Secret','Get-Secret','Remove-Secret','Get-SecretInfo','Test-SecretVault','Unregister-SecretVault','Find-Chromium')
    RequiredModules = @(
        @{
            ModuleName = 'ReallySimpleDatabase'
            RequiredVersion = '1.0.0'
        }
    )
}
