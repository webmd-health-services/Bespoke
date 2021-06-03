
function Install-BespokeZipFile
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $title = 'ZIP'
        
        $properties = @{
            'url' = '';
            'destination' = '';
            'checksum' = '';
            'items' = @()
        }

        $package = $InputObject | ConvertTo-BespokeItem -Property $properties

        [uri]$url = $package.url
        $subtitle = $url.Segments[-1]
        if( [IO.Path]::GetExtension($subtitle) -ne '.zip' )
        {
            $subtitle = "$($subtitle).zip"
        }

        $extractDir = 
            Save-BespokeUrl -Url $url -Checksum $package.checksum -Extension '.zip' |
            Expand-BespokeArchive

        # Only copy specific items from the ZIP file.
        if( $package.items )
        {
            foreach( $item in $package.items )
            {
                $sourcePath = Join-Path -Path $extractDir -ChildPath $item.path
                $destinationPath = Join-Path -Path $package.destination -ChildPath $item.path

                $source = Get-Item -Path $sourcePath -ErrorAction Ignore
                if( -not $source )
                {
                    $msg = "Item ""$($item.path)"" does not exist in ZIP archive ""$($url)""."
                    Write-Error -Message $msg
                    continue
                }

                $destinationDirPath = $destinationPath | Split-Path
                if( -not (Test-Path -Path $destinationDirPath) )
                {
                    New-Item -Path $destinationDirPath -ItemType 'Directory' | Out-Null
                }

                $destination = Get-Item -Path $destinationPath -ErrorAction Ignore
                if( $destination )
                {
                    if( $package.Checksum)
                    {
                        if( (Test-BespokeFileHash -Path $destination.FullName -Checksum $item.Checksum -ErrorAction Continue) )
                        {
                            $destinationPath | Write-BespokeState -Title $title -Subtitle $subtitle -Installed
                            continue
                        }
                    }
                    else
                    {
                        if( $source.Length -eq $destination.Length -and `
                            $source.LastWriteTime -eq $destination.LastWriteTime )
                        {
                            $destinationPath | Write-BespokeState -Title $title -Subtitle $subtitle -Installed
                            continue
                        }
                    }
                }

                $destinationPath | Write-BespokeState -Title $title -Subtitle $subtitle -NotInstalled
                $source | Copy-Item -Destination $destinationPath
            }
            return
        }

        # Copy everything from the ZIP file.
        foreach( $source in ($extractDir | Get-ChildItem -Recurse -File) )
        {
            $destinationRelativePath = $source.FullName -replace "^$([regex]::Escape($extractDir))(\\|//)", ''
            $destinationPath = Join-Path -Path $package.destination -ChildPath $destinationRelativePath
            $destination = Get-Item -Path $destinationPath -ErrorAction Ignore
            if( $destination )
            {
                if( $source.Length -eq $destination.Length -and `
                    $source.LastWriteTime -eq $destination.LastWriteTime )
                {
                    $destinationPath | Write-BespokeState -Title $title -Subtitle $subtitle -Installed
                    continue
                }
            }

            $destinationDirPath = $destinationPath | Split-Path
            if( -not (Test-Path -Path $destinationDirPath) )
            {
                New-Item -Path $destinationDirPath -ItemType 'Directory' | Out-Null
            }
            $destinationPath | Write-BespokeState -Title $title -Subtitle $subtitle -NotInstalled
            $source | Copy-Item -Destination $destinationDirPath
        }
    }
}