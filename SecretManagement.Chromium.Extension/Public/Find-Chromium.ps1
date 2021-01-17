function Find-Chromium {
    <#
    .SYNOPSIS
    Attempts to detect a chromium profile to work with. Includes common presets
    #>
    param(
        #The name of the preset folder to search for
        $Preset
    )
    #TODO: Automatic Detection
    $Presets = [ordered]@{
        EdgeCanary   = 'Microsoft/Edge SxS'
        EdgeBeta     = 'Microsoft/Edge Beta'
        Edge         = 'Microsoft/Edge'
        ChromeCanary = 'Google/Chrome SxS'
        ChromeBeta   = 'Google/Chrome Beta'
        Chrome       = 'Google/Chrome'
    }

    $ErrorActionPreference = 'Stop'

    function getUserDataFolderPath ($Preset) {
        $localAppDataPath = [Environment]::GetFolderPath('LocalApplicationData')
        return (
            Resolve-Path -Path (
                [IO.Path]::Combine(
                    $localAppDataPath,
                    $Preset,
                    'User Data'
                )
            )
        )
    }

    function getProfileNames ($UserDataFolderPath) {
        try {
            $localStatePath = Join-Path -Resolve $UserDataFolderPath 'Local State' -ErrorAction stop
        } catch {
            Write-Warning "$UserDataFolderPath exists but has no Local State file."
        }
        [String[]]$ProfileNames = (Get-Content -Raw $localStatePath | ConvertFrom-Json).profile.info_cache.psobject.properties.name
        if (-not $ProfileNames) { Write-Warning 'Local State file exists but no profile information was found' }
        return $ProfileNames
    }

    function getLoginDataPath ($Preset, $ProfileName) {
        return (
            Resolve-Path -ErrorAction Stop -Path (
                [io.path]::Combine(
                    (getUserDataFolderPath $Preset),
                    $ProfileName,
                    'Login Data'
                )
            )
        )
    }

    if ($Preset -and $Presets.$Preset) {
        #Narrow the scope to just the selected preset
        $Presets = [ordered]@{
            $Preset = $Presets.$Preset
        }
    }

    foreach ($PresetItem in $Presets.keys) {
        try {
            $userDataFolderPath = getUserDataFolderPath $Presets[$PresetItem]
            foreach ($ProfileNameItem in (getProfileNames $UserDataFolderPath)) {
                $LoginDataPath = getLoginDataPath $Presets[$PresetItem] $ProfileNameItem
                [PSCustomObject][ordered]@{
                    Name           = $PresetItem
                    Profile        = $ProfileNameItem
                    LocalStatePath = Join-Path $userDataFolderPath 'Local State'
                    LoginDataPath  = $LoginDataPath
                } | Write-Output
                Write-Verbose "SecretManagement.Chromium: Discovery FOUND $PresetItem profile at $($Presets[$PresetItem])"
            }
        } catch {
            Write-Verbose "SecretManagement.Chromium: Discovery NOT FOUND $PresetItem profile at $($Presets[$PresetItem])"
        }
    }
}