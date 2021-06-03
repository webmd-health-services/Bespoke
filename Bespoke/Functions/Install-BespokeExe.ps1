
function Install-BespokeExe
{
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $title = 'EXE'

        $properties = @{
            'name' = '';
            'url' = '';
            'programName' = '';
        }
        $package = $InputObject | ConvertTo-BespokeItem -Property $properties

        if( $package.programName -and (Get-CProgramInstallInfo -Name $package.programName) )
        {
            $package.Name | Write-BespokeState -Title $title -Installed
            return
        }

        if( -not $package.url )
        {
            Write-Error -Message 'EXE packages must have a "url" property.'
            return 
        }

        $package.Name | Write-BespokeState -Title $title -NotInstalled
        $exe = Save-BespokeUrl -Url $package.url -Checksum $package.checksum -Extension '.exe'
        Invoke-BespokeExe -Path $exe.FullName
    }
}