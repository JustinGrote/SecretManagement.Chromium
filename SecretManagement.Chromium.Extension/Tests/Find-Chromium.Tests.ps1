#requires -modules @{ModuleName="Pester"; ModuleVersion="5.1.0"}
Describe 'Find-Chromium' {
    BeforeAll {
        . "$PSScriptRoot/../Public/Find-Chromium.ps1"
    }
    AfterAll {
        Remove-Item Function:/Find-Chromium -Force -ErrorAction SilentlyContinue
    }
    It 'Searches all profiles' {
        Set-ItResult -Pending -Because 'This will be a tricky test to implement'
    }
}