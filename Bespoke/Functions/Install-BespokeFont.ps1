
function Install-BespokeFont
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $title = 'Font'

        $properties = @{
            'url' = '';
            'checksum' = '';
            'exclude' = @();
        }
        $fontInfo = $InputObject | ConvertTo-BespokeItem -Property $properties

        [uri]$url = $fontInfo.url
        $subtitle = $url.Segments[-1]

        $fontPkg = Save-BespokeUrl -Url $url -Checksum $fontInfo.Checksum
        if( $fontPkg.Extension -eq '.zip' )
        {
            $fontPkg = $fontPkg | Expand-BespokeArchive
        }

        $fontsToInstall =
            Get-ChildItem -Path $fontPkg -Include '*.ttf' -File -Recurse |
            Where-Object { 
                if( -not $fontInfo.exclude )
                {
                    return $true
                }

                [string[]]$exclude = $fontInfo.exclude
                
                $file = $_
                return (-not ($exclude | Where-Object { $file.Name -like $_ }))
            }
        
        $allUsersFontsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::Fonts)
        $userFontsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
        $userFontsPath = Join-Path -Path $userFontsPath -ChildPath 'Microsoft\Windows\Fonts'
        # Use hashes of font files to identify them. Using a file name doesn't work.
        $installedFonts = [Collections.Generic.HashSet[String]]::New()
        Get-ChildItem -Path ($allUsersFontsPath, $userFontsPath) -ErrorAction Ignore |
            ForEach-Object { Get-FileHash -LiteralPath $_.FullName } |
            Where-Object { -not $installedFonts.Contains($_.Hash) } |
            ForEach-Object { [void]$installedFonts.Add($_.Hash) }

        if( $IsWindows )
        {
            # $CopyOptions = 4 + 16;
            $shell = New-Object -ComObject 'Shell.Application'
            $fontShellNs = $shell.Namespace(0x14)  # Fonts namespace

            foreach( $fontToInstall in $fontsToInstall )
            {
                $fontFileName = $fontToInstall.Name

                $sourceHash = $fontToInstall | Get-FileHash
                if( $installedFonts.Contains($sourceHash.Hash) )
                {
                    $fontFileName | Write-BespokeState -Title $title -Subtitle $subtitle -Installed
                    continue
                }

                $fontFileName | Write-BespokeState -Title $title -Subtitle $subtitle -NotInstalled
                $fontShellNs.CopyHere($fontToInstall.FullName, '18')

                Get-ChildItem -Path $userFontsPath | Measure-Object | select -ExpandProperty Count | Write-Debug
            }
            return
        }

        $fontInstallPath = $allUsersFontsPath
        if( (Test-Path -Path $userFontsPath) )
        {
            $fontInstallPath = $userFontsPath
        }

        $fontsToInstall |
            Where-Object { 
                $sourceFile = $_
                $sourceHash = $sourceFile | Get-FileHash
                if( $installedFonts.Contains($sourceHash.Hash ) )
                {
                    $_.Name | Write-BespokeState -Title $title -Subtitle $subtitle -Installed
                    return $false
                }

                $_.Name | Write-BespokeState -Title $title -Subtitle $subtitle -NotInstalled
                return $true
            } |
            Copy-Item -Destination $fontInstallPath
    }

}