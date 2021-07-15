
function Install-BespokeWindowsFeature
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $properties = @{
            'name' = '';
        }
        $featureConfig = $InputObject | ConvertTo-BespokeItem -Property $properties -DefaultPropertyName 'name'

        $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureConfig.name
        if( -not $feature )
        {
            return
        }

        $title = 'Windows Feature'
        if( $feature.State -eq 'Installed' )
        {
            $feature.FeatureName | Write-BespokeState -Title $title -Installed
            return
        }

        $feature.FeatureName | Write-BespokeState -Title $title -NotInstalled
        Enable-WindowsOptionalFeature -FeatureName $feature.FeatureName -Online
    }
    
}