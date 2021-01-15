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
        AsCredentialEntry = $true
    }

    $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @getSecretInfoParams

    if (-not $secretInfo) {return}
    if ($secretInfo.count -gt 1) {throw 'Your secret search is ambiguous and matched multiple secrets in the vault. Please make your search more specific. Hint: Get-Secret -Name myuser@https://mysite.com/'}

    return [PSCredential]::new(
        $secretInfo.username_value,
        $(Unprotect-ChromiumString -Encrypted $secretinfo.password_value -MasterKey $SCRIPT:__VAULT["$VaultName-Key"] |
            ConvertTo-SecureString -AsPlainText -Force)
    )
}