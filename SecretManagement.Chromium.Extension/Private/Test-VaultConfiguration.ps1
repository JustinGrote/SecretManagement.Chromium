function Test-VaultConfiguration ($VaultName) {
    <#
    .SYNOPSIS
    Tests the vault configuration using the outer-scoped Test-SecretVault which has additional checks
    #>
    if (-not ( Test-SecretVault -VaultName $VaultName) ) { throw "Vault ${VaultName}: Not a valid vault configuration" }
}