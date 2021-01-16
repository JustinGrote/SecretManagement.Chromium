using namespace 'System.Security.Cryptography'

function Test-SecretVault {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName,Mandatory)]
        [string]$VaultName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [hashtable]$AdditionalParameters = (Get-Secretvault $VaultName).VaultParameters #This intelligent default is here because if you call test-secretvault from other commands it doesn't populate like it does when called from SecretManagement
    )

    Write-Verbose "SecretManagement: Testing Vault ${VaultName}"

    #Basic Sanity Checks
    if (-not $VaultName) { throw 'You must specify a Vault Name to test' }

    if (-not $AdditionalParameters.DataPath) {
        #TODO: Interactive vault selection with Out-ConsoleGridView
        throw "Vault ${VaultName}: No vaults autodetected. You must specify the Path vault parameter as a path to your Chromium Database. Hint for Chrome: `$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    }
    if (-not $AdditionalParameters.StatePath) {
        try {
            $candidateStatePath = Join-Path $AdditionalParameters.DataPath "../../Local State" -Resolve -ErrorAction stop
            Write-Verbose "Autodetected Local State file at $candidateStatePath"
            $AdditionalParameters.StatePath = $candidateStatePath
        } catch {
            throw "Vault ${VaultName}: You must specify the StatePath parameter as a path to your Chromium Database. Hint for Chrome: `$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
        }
    }
    
    $dbFile = Get-Item $AdditionalParameters.DataPath -ErrorAction Stop
    $tempDBFile = Join-Path ([io.path]::GetTempPath()) "ChromeVault-$PID-$VaultName.dbcache"
    if ((Test-Path $tempDBFile) -and (Get-FileHash $dbFile).Hash -eq (Get-FileHash $tempDBFile).Hash) {
        Write-Debug "${VaultName}: Temp DB $tempDBFile is still a valid cache"
    } else {
        #Make a copy because Chromium locks the DB file at the SQLite level and this will freeze the module trying to open it
        Write-Debug "${VaultName}: Source DB has been updated, copying to $tempDBFile"
        Copy-Item -ErrorAction Stop -Path $dbFile -Destination $tempDBFile
    }
    

    $db = ReallySimpleDatabase\Get-Database -Path $tempDBFile -WarningAction SilentlyContinue
    try {
        $db.open()
        #Loose check if it is a chromium database
        #TODO: Check table schema
        if (-not $db.getTable('logins')) {
            throw "$tempDBFile is not a valid Chromium password database (Logins table not found)"
            $db.close()
            Remove-Item $tempDBFile
        }
        $SCRIPT:__VAULT[$VaultName] = $db
    } catch {
        throw
    } finally {
        $db.close()
    }
    
    #Extract the local state encryption key if present
    if ($AdditionalParameters.StatePath) {
        $localStateInfo = Get-Content -Raw $AdditionalParameters.StatePath | ConvertFrom-Json 
        if ($localStateInfo) { 
            $encryptedkey = [convert]::FromBase64String($localStateInfo.os_crypt.encrypted_key) 
        }
        if ($encryptedkey -and [string]::new($encryptedkey[0..4]) -eq 'DPAPI') {
            # Not present in Windows PowerShell 5, nor in PS Core V6
            if ($PSVersionTable.PSVersion -lt '7.0.0') {
                throw [NotSupportedException]'Chromium v80 or later AES-encrypted passwords were detected, currently we cannot decrypt these with Windows Powershell or PS6. Please use Powershell 7'
            }
            $masterKey = [ProtectedData]::Unprotect(($encryptedkey | Select-Object -Skip 5),  $null, 'CurrentUser')
            $SCRIPT:__VAULT["$VaultName-Key"] = [AesGcm]::new($masterKey)
        } else { Write-Warning 'Could not get key for new-style encyption. Will try with older Style' }
    }

    return $true
}