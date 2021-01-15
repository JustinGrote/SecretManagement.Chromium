using namespace Microsoft.Powershell.SecretManagement
using namespace System.Security.Cryptography
using namespace System.Data
class ChromiumCredentialEntry {
    [uri]$Target
    [PSCredential]$Credential

    ChromiumCredentialEntry ([DataRow]$DataRow) {
        $this.Target = $DataRow.origin_url
        $password = $DataRow.password_value

        [Text.Encoding]::Default.GetString(
            [ProtectedData]::Unprotect(
                $DataRow.password_value,
                $null,
                [DataProtectionScope]::CurrentUser
            )
        ) | ConvertTo-SecureString -AsPlainText -Force
        
        $this.Credential = [PSCredential]::new(
            $DataRow.username_value, #username
            $password
        )
    }

    # [SecretInformation] ToSecretInformation() {
    #     return $this.Credential.Username + "@" + $this.Target.Host
    # }
    [String] ToString() {
        return $this.Credential.Username + "@" + $this.Target.Host
    }
}