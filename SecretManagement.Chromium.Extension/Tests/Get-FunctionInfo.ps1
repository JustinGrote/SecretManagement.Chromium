using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Reflection

function Get-FunctionInfo {
    <#
    .SYNOPSIS
        Get an instance of FunctionInfo.
    .DESCRIPTION
        FunctionInfo does not present a public constructor. This function calls an internal / private constructor on FunctionInfo to create a description of a function from a script block or file containing one or more functions.
    .PARAMETER IncludeNested
        By default functions nested inside other functions are ignored. Setting this parameter will allow nested functions to be discovered.
    .PARAMETER Path
        The path to a file containing one or more functions.
    .PARAMETER ScriptBlock
        A script block containing one or more functions.
    .INPUTS
        System.String
    .OUTPUTS
        System.Management.Automation.FunctionInfo
    .EXAMPLE
        Get-ChildItem -Filter *.psm1 | Get-FunctionInfo
        Get all functions declared within the *.psm1 file and construct FunctionInfo.
    .EXAMPLE
        Get-ChildItem C:\Scripts -Filter *.ps1 -Recurse | Get-FunctionInfo
        Get all functions declared in all ps1 files in C:\Scripts.
    .NOTES
        Change log:
            10/12/2015 – Chris Dent – Improved error handling.
            28/10/2015 – Chris Dent – Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPath')]
    [OutputType([System.Management.Automation.FunctionInfo])]
    param (
        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FromPath')]
        [Alias('FullName')]
        [String]$Path,

        [Parameter(ParameterSetName = 'FromScriptBlock')]
        [ScriptBlock]$ScriptBlock,

        [Switch]$IncludeNested
    )

    begin {
        $executionContextType = [PowerShell].Assembly.GetType('System.Management.Automation.ExecutionContext')
        $constructor = [FunctionInfo].GetConstructor(
            [BindingFlags]'NonPublic, Instance',
            $null,
            [CallingConventions]'Standard, HasThis',
            ([String], [ScriptBlock], $executionContextType),
            $null
        )
    }

    process {
        if ($pscmdlet.ParameterSetName -eq 'FromPath') {
            try {
                $scriptBlock = [ScriptBlock]::Create((Get-Content $Path –Raw))
            } catch {
                $ErrorRecord = @{
                    Exception = $_.Exception.InnerException
                    ErrorId   = 'InvalidScriptBlock'
                    Category  = 'OperationStopped'
                }
                Write-Error @ErrorRecord
            }
        }

        if ($scriptBlock) {
            $scriptBlock.Ast.FindAll( { 
                    param( $ast )

                    $ast -is [FunctionDefinitionAst]
                },
                $IncludeNested
            ) | ForEach-Object {
                try {
                    $internalScriptBlock = $_.Body.GetScriptBlock()
                } catch {
                    Write-Debug $_.Exception.Message
                }
                if ($internalScriptBlock) {
                    $constructor.Invoke(([String]$_.Name, $internalScriptBlock, $null))
                }
            }
        }
    }
}