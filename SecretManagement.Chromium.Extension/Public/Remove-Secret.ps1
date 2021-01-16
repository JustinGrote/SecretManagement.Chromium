function Remove-Secret {
    param (
        [string]$Name,
        [string]$VaultName,
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters
    )
    # Test-VaultConfiguration $VaultName
    Write-Warning 'Not Implemented: The Chromium vault extension is read-only for now'
    throw [NotImplementedException]'The Chromium vault extension is read-only for now'
}