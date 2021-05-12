
function Assert-BespokeFileHash
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter(Mandatory)]
        [String]$Checksum,

        [switch]$PassThru
    )

    Set-StrictMode -Version 'Latest'

    return ((Test-BespokeFileHash -Path $Path -Checksum $Checksum -ErrorAction Continue) )
}