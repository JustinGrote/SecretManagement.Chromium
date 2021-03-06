function PrepareTestEnvironment {
    $SCRIPT:testVaultName = '__PESTER'
    Microsoft.PowerShell.SecretManagement\Unregister-SecretVault -Name $testVaultName -ErrorAction SilentlyContinue
    Remove-Module SecretManagement.Chromium,SecretManagement.Chromium.Extension -ErrorAction SilentlyContinue
    if (-not (Get-Module ReallySimpleDatabase -ListAvailable -ErrorAction SilentlyContinue)) {
        Install-Module ReallySimpleDatabase -Scope CurrentUser -Force -ErrorAction Stop
    }
    Import-Module (Resolve-Path $PSScriptRoot/..) -Force

    $SCRIPT:mockDB = (Copy-Item "$PSScriptRoot/Mocks/Login Data" "$TestDrive/Login Data" -PassThru -Force)
    $SCRIPT:mockState = (Copy-Item "$PSScriptRoot/Mocks/Local State" "$TestDrive/Local State" -PassThru -Force)
    $SCRIPT:defaultVaultParams = @{
        VaultName            = $testVaultName
        AdditionalParameters = @{
            DataPath  = $mockDB.fullname
            StatePath = $mockState.fullname
        }
    }
    $SCRIPT:registerVaultParams = @{
        Name            = $testVaultName
        ModuleName      = Resolve-Path "$PSScriptRoot/../.."
        VaultParameters = @{
            DataPath  = $mockDB.fullname
            StatePath = $mockState.fullname
        }
    }
}

function TeardownTestEnvironment {
    # Remove-Module SecretManagement.Chromium.Extension -Force -ErrorAction SilentlyContinue
    # try {
    #     Remove-Item $SCRIPT:mockDB -ErrorAction Stop
    # } catch {
    #     if ($PSItem -match 'being used by another process') {
    #         throw "Vault Database is still open at end of test! Database should be closed after every operation"
    #     } elseif ($PSItem -match 'does not exist') {}
    #     else {throw}
    # }
}

function New-DeepCopyObject {
    param($DeepCopyObject)
    $memStream = New-Object IO.MemoryStream
    $formatter = New-Object Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Serialize($memStream,$DeepCopyObject)
    $memStream.Position = 0
    $formatter.Deserialize($memStream)
}