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
        $secretInfo.Name | Should -Be $secretName
        $secretInfo.VaultName | Should -be '__PESTER'
        $secretInfo.Type | Should -Be 'PSCredential'
    }

    $secretSearchTestCases = @(
        @{
            #Fully Qualified
            searchTerm = 'pester|https://twitter.com/'
            expectedResultCount = 1
            expectedNames = 'pester|https://twitter.com/'
        }
        @{
            #Explicit Domain
            searchTerm = 'https://twitter.com/'
            expectedResultCount = 3
            expectedNames = @(
                'pester|https://twitter.com/'
                'pester2|https://twitter.com/'
                'pester3|https://twitter.com/'
            )
        }
        @{
            #Wildcard Domain
            searchTerm = '*twit*'
            expectedResultCount = 3
            expectedNames = @(
                'pester|https://twitter.com/'
                'pester2|https://twitter.com/'
                'pester3|https://twitter.com/'
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
                'pester2|https://twitter.com/'
                'pester2|https://www.facebook.com/'
            )
        }
        @{
            #Wildcard Username
            searchTerm = 'pester*|'
            expectedResultCount = 6
            expectedNames = @(
                'pester|https://twitter.com/'
                'pester2|https://twitter.com/'
                'pester3|https://twitter.com/'
                'pester1|https://www.facebook.com/'
                'pester2|https://www.facebook.com/'
                'pester3|https://www.facebook.com/'
            )
        }
        @{
            #Double Wildcard Username
            searchTerm = '*pes*|'
            expectedResultCount = 6
            expectedNames = @(
                'pester|https://twitter.com/'
                'pester2|https://twitter.com/'
                'pester3|https://twitter.com/'
                'pester1|https://www.facebook.com/'
                'pester2|https://www.facebook.com/'
                'pester3|https://www.facebook.com/'
            )
        }
        @{
            #Intermediate wildcard
            searchTerm = '*p*s*|'
            expectedResultCount = 6
            expectedNames = @(
                'pester|https://twitter.com/'
                'pester2|https://twitter.com/'
                'pester3|https://twitter.com/'
                'pester1|https://www.facebook.com/'
                'pester2|https://www.facebook.com/'
                'pester3|https://www.facebook.com/'
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
                'pester|https://twitter.com/'
                'pester2|https://twitter.com/'
                'pester3|https://twitter.com/'
            )
        }
        @{
            #Http and Https
            searchTerm = 'pester*|*twitter*'
            expectedResultCount = 3
            expectedNames = @(
                'pester|https://twitter.com/'
                'pester2|https://twitter.com/'
                'pester3|https://twitter.com/'
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