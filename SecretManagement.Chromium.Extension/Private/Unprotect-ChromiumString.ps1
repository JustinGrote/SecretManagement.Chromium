#requires -modules getsql -version 5
using namespace 'System.Security.Cryptography'
function Unprotect-ChromiumString {
    param (
        #Location of the database file replace \Google\Chrome as required
        $DbPath = (Join-Path ([environment]::GetFolderPath('UserProfile')) 'AppData\Local\Google\Chrome\User Data\Default\Login Data'),
        #Location of the State file specify and empty string if nothing is to be decoded.
        $StatePath,
        #Properties to return use @{n='Name';e={Unprotect $_.Field}} to decrypt columns
        $Property = @(@{n = 'User';   e = 'username_value' }, @{n = 'Password';e = { Unprotect $_.password_value } },
            @{n = 'Created';e = { ([datetime]'1601-01-01').AddMilliseconds(($_.date_created / 1000)) } },@{n = 'realm'; e = 'signon_realm' }),
        #(optional) file path to save the Key to. You must take steps to secure the file
        $KeyPath
    )

    
    
    #region Get the master key and use it to create a AesGCcm object for decoding
    if (-not $PSBoundParameters.ContainsKey('StatePath')) { 
        $StatePath = Join-Path (Split-Path (Split-Path $DbPath)) 'Local State' 
    }
    if ($statePath) { 
        $localStateInfo = Get-Content -Raw $StatePath | ConvertFrom-Json 
    }
    if ($localStateInfo) { 
        $encryptedkey = [convert]::FromBase64String($localStateInfo.os_crypt.encrypted_key) 
    }
    if ($encryptedkey -and [string]::new($encryptedkey[0..4]) -eq 'DPAPI') {
        $masterKey = [ProtectedData]::Unprotect(($encryptedkey | Select-Object -Skip 5),  $null, 'CurrentUser')
        if ($KeyPath) { [convert]::ToBase64String($masterkey) | Out-Default $KeyPath }
        $Script:GCMKey = [AesGcm]::new($masterKey) # Not present in Windows PowerShell 5, nor in PS Core V6.
    } else { Write-Warning 'Could not get key for new-style encyption. Will try with older Style' }
    #endregion
    function Unprotect {
        # Use GCM decryption if ciphertext starts "V10" & GCMKey exists, else try ProtectedData.unprotect
        Param ( $Encrypted )
        $Script:DecodeCount ++
        try {
            if ($Script:GCMKey -and [string]::new($Encrypted[0..2]) -match 'v1\d') {
                #Ciphertext bytes run 0-2="V10"; 3-14=12_byte_IV; 15 to len-17=payload; final-16=16_byte_auth_tag
                [byte[]]$output = 1..($Encrypted.length - 31) # same length as payload.
                $Script:GCMKey.Decrypt($Encrypted[3..14]  , $Encrypted[15..($Encrypted.Length - 17)],
                    $Encrypted[-16..-1], $output, $null)
                [string]::new($output)
            } else { [string]::new([ProtectedData]::Unprotect($Encrypted,  $null, 'CurrentUser')) }
        } catch { Write-Warning "Error decoding item $Script:DecodeCount" }
    }
}
