using namespace Microsoft.Powershell.SecretManagement
function Get-SecretInfo {
    param(
        [string]$Filter,
        [string]$VaultName,
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters,
        #For internal use from other internal cmdlets
        [switch]$AsCredentialEntry
    )
    Test-VaultConfiguration $VaultName

    if ($AdditionalParameters.Delimiter) {
        $VaultDelimiter = $AdditionalParameters.Delimiter
    } else {
        $VaultDelimiter = $SCRIPT:SecretNameDelimiter
    }
    $db = $__VAULT[$vaultName]

    #First check for our special delimiter, so we know if this is an "easy" search
    $fullyQualifiedSecretNameRegex = "^.+?\${VaultDelimiter}.+?\${VaultDelimiter}(\d+)$"
    if ($filter -match $fullyQualifiedSecretNameRegex) {
        $filterQueryParts = "id = $($matches[1])"
    } elseif ($Filter -and $Filter -ne '*') {
        [String[]]$filterParts = $Filter.split("|")
        [String[]]$filterQueryParts = @()
        #Default is to search by URL
        #TODO: Escape _ and %
        if ($filterParts.count -eq 1) {
            $filterQueryParts += "origin_url LIKE '{0}'" -f $filterParts[0].replace('*','%')
        } elseif ($filterParts.count -eq 2) {
            $filterQueryParts += "username_value LIKE '{0}'" -f $filterParts[0].replace('*','%')
            if ($filterParts[1].ToCharArray().Count -gt 0) {
                $filterQueryParts += "origin_url LIKE '{0}'" -f $filterParts[1].replace('*','%')
            }
        }
    }

    #Build the fitler part of the query string
    [String]$filterQuery = $null
    if ($filterQueryParts.count -ge 1) {
        [String]$filterQuery = ' WHERE ' + ($filterQueryParts -join ' AND ')
    }

    [String]$secretInfoQuery = "SELECT * FROM logins" + $filterQuery
    try {
        $secretInfoResult = $db.InvokeSQL($secretInfoQuery) 
    } catch {
        throw
    } finally {
        $db.close()
    }

    if (-not $secretInfoResult) {
        return @()
    }

    #TODO: Cast this to chromiumCredentialEntry
    if ($AsCredentialEntry) {
        return $secretInfoResult
    } else {
        return $secretInfoResult | Foreach-Object {
            [SecretInformation]::new(
                [string](
                    $PSItem.username_value + 
                    $SecretNameDelimiter + 
                    $PSItem.origin_url + 
                    $SecretNameDelimiter +
                    $PSItem.id
                ), #Name
                [SecretType]::PSCredential,
                $VaultName
            )
        }
    }
}