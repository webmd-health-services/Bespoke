
function Expand-BespokeArchive
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [String]$Path
    )

    Set-StrictMode -Version 'Latest'

    $extractDirPath = Join-Path -Path $tempPath -ChildPath ([IO.Path]::GetRandomFileName())
    $extractDir = New-Item -Path $extractDirPath -ItemType 'Directory'

    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try
    {
        [IO.Compression.ZipFileExtensions]::ExtractToDirectory($archive, $extractDirPath)
    }
    finally
    {
        $archive.Dispose()
    }

    $extractDir | Get-ChildItem -Recurse | Out-String | Write-Debug

    return $extractDir
}
