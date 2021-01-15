function Get-Secret {
    param (
        [string]$Name,
        [string]$VaultName,
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters
    )
    Test-VaultConfiguration $VaultName

}
