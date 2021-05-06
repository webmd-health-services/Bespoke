
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

        Write-Information "    + $($name)"
        $appPkg = Save-BespokeUrl -Url $url -Checksum $package.checksum -Extension $extension
        Add-AppxPackage -Path $appPkg.FullName
    }
        
}