
function Install-BespokeExe
{
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Write-Information 'EXE'
    }

    process
    {
        $properties = @{
            'name' = '';
            'url' = '';
            'programName' = '';
        }
        $package = $InputObject | ConvertTo-BespokeItem -Property $properties

        if( $package.name -and (Get-CProgramInstallInfo -Name $package.name) )
        {
            Write-Information -Message "      $($package.installer)"
            return
        }

        if( -not $package.url )
        {
            Write-Error -Message 'EXE packages must have a "url" property.'
            return 
        }

        $exe = Save-BespokeUrl -Url $package.url -Checksum $package.checksum -Extension '.exe'
        Invoke-BespokeExe -Path $exe.FullName
    }
}