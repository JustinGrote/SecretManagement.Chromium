function Test-SecretVault {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName,Mandatory)]
        [string]$VaultName,
        [Parameter(ValueFromPipelineByPropertyName)]
        #This intelligent default is here because if you call test-secretvault from other commands it doesn't populate like it does when called from SecretManagement
        [hashtable]$AdditionalParameters = (get-secretvault $VaultName).VaultParameters
    )
    Write-Verbose "SecretManagement: Testing Vault ${VaultName}"

    #Basic Sanity Checks
    if (-not $VaultName) { throw 'You must specify a Vault Name to test' }

    if (-not $AdditionalParameters.Path) {
        #TODO: Create a default vault if path isn't supplied
        #TODO: Add ThrowUser to throw outside of module scope
        throw "Vault ${VaultName}: You must specify the Path vault parameter as a path to your Chromium Database. Hint for Chrome: `$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    }
    if (-not $AdditionalParameters.StatePath) {
        throw "Vault ${VaultName}: You must specify the StatePath parameter as a path to your Chromium Database. Hint for Chrome: `$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    }

    $dbFile = Get-Item $AdditionalParameters.Path -ErrorAction Stop
    $db = ReallySimpleDatabase\Get-Database -Path $dbFile -WarningAction SilentlyContinue
    try {
        $db.open()
        #Loose check if it is a chromium database
        if (-not $db.getTable('logins')) {throw "$dbFile is not a valid Chromium password database (Logins table not found)"}
        $SCRIPT:__VAULT[$VaultName] = $db
    } catch {
        throw
    } finally {
        $db.close()
    }

    return $true
}