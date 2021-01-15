if ($PSVersionTable.PSVersion -ge '6.0.0' -and -not $isWindows) {
    throw [NotSupportedException]'Sorry, the Chromium secret vault only works on windows due to the use of DPAPI to decrypt passwords'
}

$SCRIPT:__VAULT = @{}
$ErrorActionPreference = 'Stop'
foreach ($folderItem in 'Private','Classes') {
    Get-ChildItem "$PSScriptRoot/$folderItem/*.ps1" | Foreach-Object {
        . $PSItem.FullName
    }
}

$publicFunctions = Get-ChildItem "$PSScriptRoot/Public/*.ps1" | Foreach-Object {
    . $PSItem.FullName
    #Output the name of the function assuming it is the same as the .ps1 file so it can be exported
    $PSItem.BaseName
}

Export-ModuleMember $publicFunctions