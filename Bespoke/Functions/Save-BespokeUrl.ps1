
function Save-BespokeUrl
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Uri]$Url,

        [String]$Checksum,

        [String]$Extension
    )

    Set-StrictMode -Version 'Latest'

    $algorithm = 'sha512'
    if( $Checksum -match '^([^:]+):(.+)$' )
    {
        $algorithm = $Matches[1]
        $Checksum = $Matches[2]
    }

    $urlBytes = [Text.Encoding]::UTF8.GetBytes($Url.ToString())
    $hasher = [Security.Cryptography.HashAlgorithm]::Create('sha512')
    $hashBytes = $hasher.ComputeHash($urlBytes)
    $urlHash = [BitConverter]::ToString($hashBytes).ToLowerInvariant() -replace '-',''
    $urlHash = $urlHash.Substring(0, 8)

    if( $Extension -and $Extension[0] -ne '.' )
    {
        $Extension = ".$($Extension)"
    }

    $basename = [IO.Path]::GetFileNameWithoutExtension($Url.Segments[-1])
    $originalExtension = [IO.Path]::GetExtension($Url.Segments[-1])
    if( $Extension -and $originalExtension -eq $Extension )
    {
        $Extension = ''
    }

    $outFileName = "$($basename)+$($urlHash)$($originalExtension)$($Extension)"
    $outFilePath = Join-Path -Path $cachePath -ChildPath $outFileName

    if( (Test-Path -Path $outFilePath) )
    {
        $outFile = Get-Item -Path $outFilePath
        $hash = Get-FileHash -Path $outFilePath -Algorithm $algorithm
        if( -not $Checksum )
        {
            return $outFile
        }

        if( $hash.Hash -eq $Checksum )
        {
            return $outFile
        }
    }

    Write-Debug -Message ("$($Url) -> $($outFilePath)")
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $outFilePath

    if( -not (Test-Path -Path $outFilePath) )
    {
        Write-Error -Message "Failed to download ""$($Url)""."
        return
    }

    $hash = Get-Filehash -Path $outFilePath -Algorithm $algorithm
    if( $Checksum -and $hash.Hash -ne $Checksum )
    {
        $msg = "Checksum mismatch: the ""$($outFilePath)"" file's checksum ""$($hash.Hash.ToLowerInvariant())"" " +
               "doesn't match expected ""$($algorithm)"" checksum ""$($Checksum)""."
        Write-Error -Message $msg
        return
    }

    if( -not $Checksum )
    {
        $msg = "Checksum of ""$($Url)"" is ""$($hash.Hash.ToLowerInvariant())"". Please add this to " +
               'your bespoke.json.'
        Write-Warning -Message $msg

    }

    return Get-Item -Path $outFilePath
}