using namespace System.Security.Cryptography
function Unprotect-ChromiumString {
    param (
        #The encrypted string that you wish to decode
        [Parameter(Mandatory)][byte[]]$Encrypted,
        #The encrypted key from the local state file
        [AesGcm]$MasterKey
    )

    $EncryptedString = [string]::new($Encrypted)

    if ($MasterKey -and [String]::new($EncryptedString[0..2]) -match 'v1\d') {
        #Ciphertext bytes run 0-2="V10"; 3-14=12_byte_IV; 15 to len-17=payload; final-16=16_byte_auth_tag
        [byte[]]$output = 1..($EncryptedString.length - 31) # same length as payload.
        $MasterKey.Decrypt(
            $EncryptedString[3..14], 
            $EncryptedString[15..($EncryptedString.Length - 17)],
            $EncryptedString[-16..-1], 
            $output,
            $null
        )
        return [string]::new($output)
    } else { 
        return [string]::new([ProtectedData]::Unprotect($EncryptedString, $null, 'CurrentUser'))
    }
}