

function Install-ZipFile
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
            'name' = '';
            'url' = '';
            'installer' = '';
            'programName' = '';
        }
        $package = $InputObject | ConvertTo-BespokeItem -Property $properties

        if( -not $package.installer )
        {
            Write-Error -Message 'Zip packages must have an "installer" property.'
            return
        }

        if( $package.programName -and (Get-CProgramInstallInfo -Name $package.programName) )
        {
            Write-Information -Message "      $($package.installer)"
            return
        }

        if( -not $package.url )
        {
            Write-Error -Message 'Zip packages must have a "url" property.'
            return 
        }

        $zip = Save-BespokeUrl -Url $package.url -Checksum $package.checksum -Extension '.zip'
        $extractPath = Join-Path -Path $cachePath -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $extractPath -ItemType 'Directory' | Out-Null

        try 
        {
            $archive = [IO.Compression.ZipFile]::OpenRead($zip.FullName)
            try
            {
                [IO.Compression.ZipFileExtensions]::ExtractToDirectory($archive, $extractPath)
            }
            finally
            {
                $archive.Dispose()
            }

            Get-ChildItem $extractPath -Recurse | Out-String | Write-Debug
            $installerPath = Join-Path -Path $extractPath -ChildPath $package.installer
            if( -not (Test-Path -Path $installerPath -PathType Leaf) )
            {
                $msg = "ZIP archive ""$($url)"" doesn't contain file ""$($package.installer)""."
                Write-Error -Message $msg
                return
            }

            $installerExtension = [IO.Path]::GetExtension($package.installer)
            switch( $installerExtension )
            {
                '.exe'
                {
                    Write-Information "    + $($installerPath | Split-Path -Leaf)"
                    $processName = [IO.Path]::GetFileNameWithoutExtension($installerPath)
                    & $installerPath
                    $installerProcess = Get-Process -Name $processName -ErrorAction Ignore
                    if( $installerProcess )
                    {
                        # Must read handle to get an exit code.
                        $installerProcess.Handle | Out-Null
                        $installerProcess.WaitForExit()
                        if( $installerProcess.ExitCode )
                        {
                            $msg = "Installer ""$($installerPath | Split-Path -Leaf)"" returned non-zero exit code " +
                                    """$($installerProcess.Exitcode)""."
                            Write-Error -Message $msg
                            return
                        }
                    }
                }
                default
                {
                    $msg = "Unable to run ""$($installerExtension)"" installers. Only .exe files are supported."
                    Write-Error -Message $msg
                    return
                }
            }
        }
        finally
        {
            if( (Test-Path -Path $extractPath) )
            {
                Remove-Item -Path $extractPath -Recurse -ErrorAction Ignore
            }
        }
    }
}