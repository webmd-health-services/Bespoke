
function Install-AppxPackage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Write-Information 'Windows Store'
    }

    process
    {
        $properties = @{
            'url' = '';
            'isBundle' = $false;
            'checksum' = '';
        }

        $package = $InputObject | ConvertTo-BespokeItem -DefaultPropertyName 'name' -Properties $properties

        if( Get-AppxPackage -Name $package.name )
        {
            Write-Information "      $($name)"
            continue
        }

        $extension = '.appx'
        if( $package.isBundle )
        {
            $extension = '.appxbundle'
        }

        Write-Information "    + $($name)"
        $appPkgFilePath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "$($name)$($extension)"
        try
        {
            Invoke-WebRequest -Uri $url -OutFile $appPkgFilePath
            if( $package.checksum )
            {
                $hash = Get-FileHash -Path $appPkgFilePath
                if( $package.checksum -ne $hash.Hash )
                {
                    $msg = "Download of Windows Store package ""$($package.name)"" failed: downloaded file checksum " +
                           """$($hash.Hash.ToLowerInvariant())"" doesn't match expected checksum " +
                           """$($package.checksum.ToLowerInvariant())""."
                    Write-Error -Message $msg
                    return
                }
            }
            
            Add-AppxPackage -Path $appPkgFilePath
        }
        finally
        {
            Remove-Item -Path $appPkgFilePath -ErrorAction Ignore
        }

    }
        
}