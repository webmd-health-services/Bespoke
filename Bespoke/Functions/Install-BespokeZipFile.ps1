
function Install-BespokeZipFile
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Write-Information 'ZIP'
    }

    process
    {
        $properties = @{
            'url' = '';
            'destination' = '';
            'checksum' = '';
            'items' = @()
        }

        $package = $InputObject | ConvertTo-BespokeItem -Property $properties

        $extractDir = 
            Save-BespokeUrl -Url $package.Url -Checksum $package.checksum -Extension '.zip' |
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
                    $msg = "Item ""$($item.path)"" does not exist in ZIP archive ""$($package.Url)""."
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
                    $infoMsg = "      $($destinationPath)"
                    if( $package.Checksum)
                    {
                        if( (Test-BespokeFileHash -Path $destination.FullName -Checksum $item.Checksum -ErrorAction Continue) )
                        {
                            Write-Information $infoMsg
                            continue
                        }
                    }
                    else
                    {
                        if( $source.Length -eq $destination.Length -and `
                            $source.LastWriteTime -eq $destination.LastWriteTime )
                        {
                            Write-Information $infoMsg
                            continue
                        }
                    }
                }

                Write-Information "    + $($destinationPath)"
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
                    Write-Information "      $($destinationPath)"
                    continue
                }
            }

            $destinationDirPath = $destinationPath | Split-Path
            if( -not (Test-Path -Path $destinationDirPath) )
            {
                New-Item -Path $destinationDirPath -ItemType 'Directory' | Out-Null
            }
            Write-Information "    + $($destinationPath)"
            $source | Copy-Item -Destination $destinationDirPath
        }
    }
}