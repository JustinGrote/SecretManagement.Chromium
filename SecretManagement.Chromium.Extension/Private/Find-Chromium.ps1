function Find-Chromium {
    <#
    .SYNOPSIS
    Attempts to detect a chromium profile to work with. Includes common presets
    #>
    param(
        #The name of the preset folder to search for
        $Preset,
        #Name of the browser user profile
        $ProfileName = 'Default'
    )
    #TODO: Automatic Detection
    $Presets = [ordered]@{
        Edge = 'Microsoft/Edge'
        EdgeBeta = 'Microsoft/Edge Beta'
        EdgeCanary = 'Microsoft/Edge SxS'
        Chrome = 'Google/Chrome'
        ChromeBeta = 'Google/Chrome Beta'
        ChromeCanary = 'Google/Chrome SxS'
    }

    function GetLoginDataPath ($Preset, $ProfileName) {
        $localAppDataPath = [Environment]::GetFolderPath('LocalApplicationData')
        return ([io.path]::Combine(
            $localAppDataPath,
            $Preset,
            'User Data',
            $ProfileName,
            'Login Data'
        ))
    }

    if ($Preset -and $Presets.$Preset) {
        return (GetLoginDataPath $Presets[$Preset] $ProfileName)
    } else {
        foreach ($PresetEntry in $Presets.keys) {
            $pathToTest = GetLoginDataPath -Preset ($Presets[$PresetEntry]) -ProfileName $ProfileName
            #Return first Entry
            #TODO: Present a choice
            try {
                $validPath = Resolve-Path $pathToTest -ErrorAction Stop
                Write-Verbose "SecretManagement.Chromium: Autodetected $PresetEntry profile at $($Presets[$PresetEntry])"
                $validPath
                break
            } catch {}
        }
    }
}