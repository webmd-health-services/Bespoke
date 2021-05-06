
function Install-BespokeFileLink
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter(Mandatory)]
        [String]$DestinationDirectory,

        [switch]$Invoke
    )

    Set-StrictMode -Version 'Latest'

    if( -not (Test-Path -Path $DestinationDirectory) )
    {
        New-Item -ItemType 'Directory' -Path $DestinationDirectory -Force | Out-Null
    }

    $destinationPath = Join-Path -Path $DestinationDirectory -ChildPath ($Path | Split-Path -Leaf)
    if( (Test-Path -Path $destinationPath) )
    {
        Write-Information "   $($destinationPath)"
        return
    }

    Write-Information " + $($destinationPath)"
    New-Item -ItemType 'HardLink' -Link $destinationPath -Target $Path
}