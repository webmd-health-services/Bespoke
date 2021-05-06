
function Test-BespokeItem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    process
    {
        if( $InputObject -is [String] -or -not ($InputObject | Get-Member '$if') )
        {
            return $true
        }

        Invoke-Expression $InputObject.'$if' | Write-Output
    }
}