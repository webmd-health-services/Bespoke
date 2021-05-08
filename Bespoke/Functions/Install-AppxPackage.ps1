
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
            'externalPackages' = ''
        }

        $package = $InputObject | ConvertTo-BespokeItem -DefaultPropertyName 'name' -Property $properties

        if( Get-AppxPackage -Name $package.name )
        {
            Write-Information "      $($package.name)"
            return
        }

        $extension = '.appx'
        if( $package.isBundle )
        {
            $extension = '.appxbundle'
        }

        Write-Information "    + $($package.name)"
        $appPkg = Save-BespokeUrl -Url $package.url -Checksum $package.checksum -Extension $extension

        $conditionalParams = @{}
        if( $package.externalPackages )
        {
            $conditionalParams['ExternalPackages'] = $package.externalPackages
        }

        Add-AppxPackage -Path $appPkg.FullName @conditionalParams
    }
        
}