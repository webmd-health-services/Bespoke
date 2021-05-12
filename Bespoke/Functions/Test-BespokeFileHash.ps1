
function Test-BespokeFileHash
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter(Mandatory, ParameterSetName)]
        [String]$Checksum,

        [switch]$PassThru
    )

    Set-StrictMode -Version 'Latest'

    if( -not $PSBoundParameters.ContainsKey('ErrorAction') )
    {
        $ErrorActionPreference = [Management.Automation.ActionPreference]::Ignore
    }

    $algorithm = 'SHA512'
    if( $Checksum -match '^([^:]+):(.+)$' )
    {
        $algorithm = $Matches[1]
        $Checksum = $Matches[2]
    }

    $hash = Get-Filehash -Path $Path -Algorithm $algorithm
    $result = ($hash.Hash -eq $Checksum)
    
    if( -not $result )
    {
        $msg = "Checksum mismatch: the ""$($Path | Resolve-Path -Relative)"" file's $($algorithm) checksum " +
            """$($hash.Hash.ToLowerInvariant())"" doesn't match expected checksum " +
            """$($Checksum.ToLowerInvariant())"". To use a different checksum algorithm, prefix the checksum " +
            "with the algorithm name followed by a colon, e.g. ""sha256:$($Checksum)"". Acceptable algorithms " +
            'are ' + [Environment]::NewLine +
            ' ' + [Environment]::NewLine +
            ' * SHA1' + [Environment]::NewLine +
            ' * SHA256' + [Environment]::NewLine +
            ' * SHA384' + [Environment]::NewLine +
            ' * SHA512 (default)' + [Environment]::NewLine +
            ' * MACTripleDES' + [Environment]::NewLine +
            ' * MD5' + [Environment]::NewLine +
            ' * RIPEMD160' + [Environment]::NewLine

        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
    }

    if( $PassThru )
    {
        return $hash
    }
    else
    {
        return $result
    }
}