
function Install-WingetPackage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        # $wingetInstalledApps = 
        #     winget list |
        #     ForEach-Object { $_ } |
        #     Select-Object -Skip 4 | 
        #     ForEach-Object { $_ -replace 'ΓÇª', ' ' } |
        #     ForEach-Object { 
        #         [pscustomobject]@{ 
        #             'Name' = $_.Substring(0,49).TrimEnd();
        #             'Id' = $_.Substring(49,51).Trim();
        #             'Version' = $_.Substring(100).Trim() } 
        #     }

        Install-Winget
    }

    process
    {
        $properties = @{
            'installId' = '';
            'listId' = '';
        }
        $package = $InputObject | ConvertTo-BespokeItem -DefaultPropertyName 'name' -Property $properties

        $listId = $package.name
        if( $package.listId )
        {
            $listId = $package.listId
        }

        $msg = $package.name
        if( (winget list --id $listId | Select-Object -Skip 4) )
        {
            $msg | Write-BespokeState -Title 'winget' -Installed
            return
        }

        $installId = $package.name
        if( $package.installId )
        {
            $installId = $package.searchId
        }

        $msg | Write-BespokeState -Title 'winget' -NotInstalled
        winget install $installId
    }
}