function Remove-Secret {
    param (
        [string]$Name,
        [string]$VaultName,
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters
    )
    Test-VaultConfiguration $VaultName
    throw [NotImplementedException]'This vault extension is read-only for now'
}