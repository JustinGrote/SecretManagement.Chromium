function Register-ChromiumSecretVault {
    <#
    .SYNOPSIS
    A convenience Cmdlet to automatically register typical installed VaultParameters
    .EXAMPLE
    Register-ChromiumSecretVault
    Detects all Chromium-based secret vaults in the preset list and registers them
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #Select one of the available preset vaults to register
        [ValidateSet(
            #TODO: Enum for this if I can figure out the powershell module nesting trickiness
            'Edge','EdgeBeta','EdgeCanary','Chrome','ChromeBeta','ChromeCanary'
        )][String]$Preset,
        #Specify to overwrite vaults already present
        [Switch]$AllowClobber,
        #Specify the path to Chromium.SecretManagement if it is not in your default module path. This is typically only used for debugging.
        [String]$ModuleName = $(Split-Path (Get-Module SecretManagement.Chromium).Path)
    )

    $findChromiumParams = @{}
    if ($Preset) {$findChromiumParams.Preset = $Preset}
    foreach ($profileItem in Find-Chromium @findChromiumParams) {
        $VaultName = $ProfileItem.Name
        if ($ProfileItem.Profile -ne 'Default') {
            $VaultName += '-' + $ProfileItem.Profile
        }
        
        if ($PSCmdlet.ShouldProcess($VaultName, 'Register Chromium Secret Vault')) {
            $registerVaultParams = @{
                Name = $VaultName
                ModuleName = $moduleName
                AllowClobber = $AllowClobber
                VaultParameters = @{
                    DataPath = [String]$ProfileItem.LoginDataPath
                    StatePath = [String]$ProfileItem.LocalStatePath
                }
                Description = $ProfileItem.Name,
                    'Profile',
                    $ProfileItem.Profile,
                    'at',
                    (Split-Path $ProfileItem.LoginDataPath) -join ' '
            }

            try {
                Register-SecretVault @registerVaultParams
            } catch {
                if ($PSItem.FullyQualifiedErrorId -eq 'RegisterSecretVaultInvalidVaultName,Microsoft.PowerShell.SecretManagement.RegisterSecretVaultCommand') {
                    write-warning "$VaultName is already registered. Skipping..."
                } else {throw}
            }
        }
    }

}