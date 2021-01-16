#requires -modules @{ModuleName="Pester"; ModuleVersion="5.1.0"}
Describe 'Get-SecretInfo' {
    
    BeforeEach {
        . $PSScriptRoot/Shared.ps1
        PrepareTestEnvironment
        Register-SecretVault @registerVaultParams
    }
    AfterEach {
        TeardownTestEnvironment
        $testVault | Microsoft.Powershell.SecretManagement\Unregister-SecretVault -ErrorAction SilentlyContinue
    }
    It 'All secrets' {
        $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @defaultVaultParams
        $secretInfo | Should -HaveCount 8
    }

    It 'Secret by fully qualified name' {
        $secretName = 'pester|https://twitter.com/'
        $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @defaultVaultParams -Filter $secretName
        $secretInfo | Should -HaveCount 1
        $secretInfo.Name | Should -Be "pester${D}https://twitter.com/${D}2"
        $secretInfo.VaultName | Should -be '__PESTER'
        $secretInfo.Type | Should -Be 'PSCredential'
    }
    
    $SCRIPT:D = "|"
    $secretSearchTestCases = @(
        @{
            #Fully Qualified
            searchTerm = "pester|https://twitter.com/"
            expectedResultCount = 1
            expectedNames = "pester${D}https://twitter.com/${D}2"
        }
        @{
            #Explicit Domain
            searchTerm = 'https://twitter.com/'
            expectedResultCount = 3
            expectedNames = @(
                "pester${D}https://twitter.com/${D}2"
                "pester2${D}https://twitter.com/${D}3"
                "pester3${D}https://twitter.com/${D}4"
            )
        }
        @{
            #Wildcard Domain
            searchTerm = '*twit*'
            expectedResultCount = 3
            expectedNames = @(
                "pester${D}https://twitter.com/${D}2"
                "pester2${D}https://twitter.com/${D}3"
                "pester3${D}https://twitter.com/${D}4"
            )
        }
        @{
            #Wildcard Domain w/ mistake
            searchTerm = '*twit*xxxmistyped*'
            expectedResultCount = 0
        }
        @{
            #Explicit Username
            searchTerm = 'pester2|'
            expectedResultCount = 2
            expectedNames = @(
                "pester2${D}https://twitter.com/${D}3"
                "pester2${D}https://www.facebook.com/${D}7"
            )
        }
        @{
            #Wildcard Username
            searchTerm = 'pester*|'
            expectedResultCount = 6
            expectedNames = @(
                "pester${D}https://twitter.com/${D}2"
                "pester2${D}https://twitter.com/${D}3"
                "pester3${D}https://twitter.com/${D}4"
                "pester1${D}https://www.facebook.com/${D}6"
                "pester2${D}https://www.facebook.com/${D}7"
                "pester3${D}https://www.facebook.com/${D}8"
            )
        }
        @{
            #Double Wildcard Username
            searchTerm = '*pes*|'
            expectedResultCount = 6
            expectedNames = @(
                "pester${D}https://twitter.com/${D}2"
                "pester2${D}https://twitter.com/${D}3"
                "pester3${D}https://twitter.com/${D}4"
                "pester1${D}https://www.facebook.com/${D}6"
                "pester2${D}https://www.facebook.com/${D}7"
                "pester3${D}https://www.facebook.com/${D}8"
            )
        }
        @{
            #Intermediate wildcard
            searchTerm = '*p*s*|'
            expectedResultCount = 6
            expectedNames = @(
                "pester${D}https://twitter.com/${D}2"
                "pester2${D}https://twitter.com/${D}3"
                "pester3${D}https://twitter.com/${D}4"
                "pester1${D}https://www.facebook.com/${D}6"
                "pester2${D}https://www.facebook.com/${D}7"
                "pester3${D}https://www.facebook.com/${D}8"
            )
        }
        @{
            #Intermediate wildcard with wrong term
            searchTerm = '*p*xxxmistyped*|'
            expectedResultCount = 0
        }
        @{
            #Combined Intermediate wildcard
            searchTerm = 'pester*|*twitter*'
            expectedResultCount = 3
            expectedNames = @(
                "pester${D}https://twitter.com/${D}2"
                "pester2${D}https://twitter.com/${D}3"
                "pester3${D}https://twitter.com/${D}4"
            )
        }
        @{
            #Http and Https
            searchTerm = 'pester*|*twitter*'
            expectedResultCount = 3
            expectedNames = @(
                "pester${D}https://twitter.com/${D}2"
                "pester2${D}https://twitter.com/${D}3"
                "pester3${D}https://twitter.com/${D}4"
            )
        }
    )
    It 'Secret Search <searchTerm>' -TestCases $secretSearchTestCases {
        $secretInfo = SecretManagement.Chromium.Extension\Get-SecretInfo @defaultVaultParams -Filter $searchTerm
        $secretInfo | Should -HaveCount $expectedResultCount
        $secretInfo.Name.foreach{
            $PSItem | Should -BeIn $ExpectedNames
        }
        $secretInfo.VaultName.foreach{
            $PSItem | Should -be '__PESTER'
        } 
        $secretInfo.Type.foreach{
            $PSItem | Should -Be 'PSCredential'
        } 
    }
}