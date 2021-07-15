

function Install-BespokeMsi
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    begin
    {
    }

    process
    {
        Set-StrictMode -Version 'Latest'

        $properties = @{
            'name' = '';
            'url' = '';
            'archiveInstallerPath' = '';
            'programName' = '';
            'checksum' = '';
            'type' = '';
        }
        $package = $InputObject | ConvertTo-BespokeItem -Property $properties

        $title = 'MSI'

        if( $package.programName -and (Get-CProgramInstallInfo -Name $package.programName -ErrorAction SilentlyContinue) )
        {
            $package.programName | Write-BespokeState -Title $title -Installed
            return
        }

        if( -not $package.url )
        {
            Write-Error -Message 'MSI packages must have a "url" property.'
            return 
        }

        [Uri]$url = $package.url
        $type = $package.type
        if( -not $type )
        {
            $type = [IO.Path]::GetExtension($url.Segments[-1]) -replace '^\.',''
        }

        if( $type -notin @('exe', 'msi', 'zip') )
        {
            $msg = "Unsupported MSI installer type ""$($downloadType)"". Supported types are ""exe"", ""msi"", or " +
                   '"zip". We usually detect the type based on the extension of the download URL. If the download ' +
                   'URL doesn''t end with one of those extensions, use the "type" property to explicitly state what ' +
                   'type the downloaded file is.'
            Write-Error -Message $msg
            return
        }

        $extractPath = ''
        try
        {
            $installer = Save-BespokeUrl -Url $package.url -Checksum $package.checksum -Extension ".$($type)"
            if( $type -eq 'zip' )
            {
                if( -not $package.archiveInstallerPath )
                {
                    $msg = 'When installing a zip-compressed package, the path to the .msi/.exe installer in the ZIP ' +
                        'archive to run must be given by the "archiveInstallerPath" property.'
                    Write-Error -Message $msg
                    return
                }
        
                $extractPath = Expand-BespokeArchive -Path $installer.FullName

                $installerPath = Join-Path -Path $extractPath -ChildPath $package.archiveInstallerPath
                if( -not (Test-Path -Path $installerPath -PathType Leaf) )
                {
                    $msg = "ZIP archive ""$($url)"" doesn't contain file ""$($package.archiveInstallerPath)""."
                    Write-Error -Message $msg
                    return
                }
                $installer = Get-Item -Path $installerPath

                $type = $installer.Extension -replace '^\.', ''
                if( $type -notin @('exe', 'msi') )
                {
                    $msg = "Invalid installer extension ""$($type)"". When downloading zipped installers, the " +
                           'installer''s extension in the ZIP file must be ".exe" or ".msi".'
                    Write-Error -Message $msg
                    return 
                }
            }

            $installer.Name | Write-BespokeState -Title $title -NotInstalled
            switch( $type )
            {
                'exe'
                {
                    Invoke-BespokeExe -Path $installer.FullName
                }
                'msi'
                {
                    Install-CMsi -Path $installer.FullName
                }
            }
        }
        finally
        {
            if( $extractPath -and (Test-Path -Path $extractPath) )
            {
                Remove-Item -Path $extractPath -Recurse -ErrorAction Ignore
            }
        }
    }
}