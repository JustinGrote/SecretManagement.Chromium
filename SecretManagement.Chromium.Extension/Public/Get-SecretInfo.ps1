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

    $db = $__VAULT[$vaultName]
    if ($Filter -and $Filter -ne '*') {
        [String[]]$filterParts = $Filter.split('|')
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
        
        [String]$filterQuery = $null
        if ($filterQueryParts.count -ge 1) {
            [String]$filterQuery = ' WHERE ' + ($filterQueryParts -join ' AND ')
        }
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
                    '|' + 
                    $PSItem.origin_url
                ), #Name
                [SecretType]::PSCredential,
                $VaultName
            )
        }
    }
    #TODO: Implement SecretInfo

    # $KeepassParams = GetKeepassParams -VaultName $VaultName -AdditionalParameters $AdditionalParameters
    # $KeepassGetResult = Get-KPEntry @KeepassParams | 
    #     ConvertTo-KPPSObject |
    #     Where-Object {$_ -notmatch '^.+?/Recycle Bin/'}

    # [Object[]]$secretInfoResult = $KeepassGetResult | Where-Object Title -like $Filter | Foreach-Object {
    #     #TODO: Find out why the fully qualified is required on Linux even though using Namespace is defined above
    #     [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
    #         $PSItem.Title, #string name
    #         [Microsoft.PowerShell.SecretManagement.SecretType]::PSCredential, #SecretType type
    #         $VaultName #string vaultName
    #     )
    # }

    # [Object[]]$sortedInfoResult = $secretInfoResult | Sort-Object -Unique Name
    # if ($sortedInfoResult.count -lt $secretInfoResult.count) {
    #     $filteredRecords = (Compare-Object $sortedInfoResult $secretInfoResult | Where-Object SideIndicator -eq '=>').InputObject
    #     Write-Warning "Vault ${VaultName}: Entries with non-unique titles were detected, the duplicates were filtered out. Duplicate titles are currently not supported with this extension, ensure your entry titles are unique in the database."
    #     Write-Warning "Vault ${VaultName}: Filtered Non-Unique Titles: $($filteredRecords -join ', ')"
    # }
    # $sortedInfoResult
}