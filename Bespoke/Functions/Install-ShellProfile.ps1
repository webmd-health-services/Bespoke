
function Install-ShellProfile
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
            'shell' = '';
            'host' = 'CurrentUserAllHosts';
            'source' = '';
        }
        $profileInfo = $InputObject | ConvertTo-BespokeItem -Property $properties

        $title = ''
        switch( $profileInfo.shell )
        {
            'powershell'
            {
                $subtitle = 'PowerShell'
                $targetPath = Join-Path -Path $bespokeRoot -ChildPath $profileInfo.source
                $hostName = $profileInfo.host
                if( -not ($profile | Get-Member $profileInfo.host) )
                {
                    $hostNames = $profile | Get-Member -Name '*host*' | Select-Object -ExpandProperty 'Name'
                    $msg = "Invalid PowerShell host ""$($profileInfo.host)"". Must be one of " +
                           """$($hostNames -join ', ')""."
                    Write-Error -Message $msg
                }
                $linkPath = $profile.$hostName
            }
            default
            {
                Write-Error -Message "Unsupported shell ""$($profileInfo.shell)""."
                return
            }
        }

        if( -not (Test-Path -Path $targetPath -PathType Leaf) )
        {
            Write-Error -Message "Source profile ""$($targetPath)"" doesn't exist."
            return
        }

        if( (Test-Path -Path $linkPath) )
        {
            $link = Get-Item -Path $linkPath
            if( $link.Target -contains $targetPath )
            {
                $linkPath | Write-BespokeState -Title 'Profile' -Subtitle $subtitle -Installed
                return
            }

            Write-Error -Message "Profile ""$($linkPath)"" already exists. Please set aside this file and re-run bespoke."
            return
        }

        $linkPath | Write-BespokeState -Title $title -NotInstalled
        New-Item -ItemType 'Hardlink' -Path $linkPath -Target $targetPath | Out-Null
    }
}