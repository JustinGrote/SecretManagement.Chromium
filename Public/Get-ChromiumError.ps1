function Get-ChromiumError {
<#
.SYNOPSIS
Retrieve a more detailed reason why the last vault command failed. 
.NOTES
This will be deprecated when https://github.com/PowerShell/SecretManagement/issues/93 is addressed
#>
    param(
        $Newest = 1
    )
    
    [Exception[]]$vaultErrors = $GLOBAL:Error.where{$PSItem.CategoryInfo.TargetType -eq 'ExtensionVaultModule'}.Exception | 
        Select-Object -First $Newest
        
    if ($vaultErrors) {
        foreach ($errorItem in $vaultErrors) {
            [String]$errorMessage = $errorItem.message + ': ' + $errorItem.InnerException.Message
            $Host.UI.WriteErrorLine($errorMessage)
        }
    }
}