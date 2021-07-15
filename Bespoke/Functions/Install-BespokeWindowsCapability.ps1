
function Install-BespokeWindowsCapability
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
        $capabilityConfig = $InputObject | ConvertTo-BespokeItem -Property $properties -DefaultPropertyName 'name'

        $capability = Get-WindowsCapability -Online -Name $capabilityConfig.name
        if( -not $capability )
        {
            return
        }

        $title = 'Windows Capability'
        if( $capability.State -ne [Microsoft.Dism.Commands.PackageFeatureState]::NotPresent )
        {
            $capability.Name | Write-BespokeState -Title $title -Installed
            return
        }

        $capability.Name | Write-BespokeState -Title $title -NotInstalled
        Add-WindowsCapability -Name $capability.Name -Online
    }
    
}