
function Install-AppxPackage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $properties = @{
            
            'url' = '';
            'isBundle' = $false;
            'checksum' = '';
            'externalPackages' = ''
        }

        $package = $InputObject | ConvertTo-BespokeItem -DefaultPropertyName 'name' -Property $properties

        if( Get-AppxPackage -Name $package.name )
        {
            $package.name | Write-BespokeState -Title 'Appx' -Installed
            return
        }

        $extension = '.appx'
        if( $package.isBundle )
        {
            $extension = '.appxbundle'
        }

        $package.name | Write-BespokeState -Title 'Appx' -NotInstalled
        $appPkg = Save-BespokeUrl -Url $package.url -Checksum $package.checksum -Extension $extension

        $conditionalParams = @{}
        if( $package.externalPackages )
        {
            $conditionalParams['ExternalPackages'] = $package.externalPackages
        }

        Add-AppxPackage -Path $appPkg.FullName @conditionalParams
    }
        
}