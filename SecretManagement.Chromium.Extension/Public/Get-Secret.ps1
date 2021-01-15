function Get-Secret {
    param (
        [string]$Name,
        [string]$VaultName,
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters
    )
    if (-not $Name) {throw 'You must specify a specific secret name or SecretInformation object to this command. Hint: (Get-SecretInfo)[0]'}

    Test-VaultConfiguration $VaultName

    $getSecretInfoParams = @{
        Filter = $Name
        VaultName = $VaultName
        AdditionalParameters = $AdditionalParameters
    }
    $getSecretInfoParams.AdditionalParameters.AsCredentialEntry = $true

    $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @getSecretInfoParams

    return [PSCredential]::new(
        $secretInfo.username_value,
        $(Unprotect-ChromiumString -Encrypted $secretinfo.password_value -MasterKey $SCRIPT:__VAULT["$VaultName-Key"] |
            ConvertTo-SecureString -AsPlainText -Force)
    )
}