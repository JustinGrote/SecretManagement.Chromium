using namespace Microsoft.Powershell.SecretManagement
function Get-SecretInfo {
    param(
        [string]$Filter,
        [string]$VaultName,
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters
    )
    Test-VaultConfiguration $VaultName

    $db = $__VAULT[$vaultName]
    if ($Filter -and $Filter -ne '*') {
        [String[]]$filterParts = $Filter.split('|')
        $filterQueryParts = @()
        if ($filterParts[0]) {
            $filterQueryParts += "signon_realm LIKE '%{0}%'" -f $filterParts[1]
        }
        if ($filterParts.count -eq 2) {
            $filterQueryParts += "username_value = '{0}'" -f $filterParts[0]
        }
        
        [String]$filterQuery = $null
        if ($filterParts[1]) {
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

    #TODO: Cast this to chromiumCredentialEntry
    if ($AdditionalParameters.AsCredentialEntry) {
        return $secretInfoResult
    } else {
        return $secretInfoResult | Foreach-Object {
            [SecretInformation]::new(
                [string]($PSItem.username_value + '|' + [uri]$PSItem.origin_url), #Name
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