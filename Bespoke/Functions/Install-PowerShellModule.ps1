
function Install-PowerShellModule
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        $title = 'PowerShell Modules'

        $pkgMgmtModules = @( 'PackageManagement', 'PowerShellGet' )
        foreach( $pkgMgmtModule in $pkgMgmtModules )
        {
            $module = 
                Get-Module -Name $pkgMgmtModule -ListAvailable | 
                Where-Object 'Version' -GT '1.0.0.1' |
                Sort-Object -Descending -Property 'Version' |
                Select-Object -First 1
            if( $module )
            {
                "$($module.Name) $($module.Version)" | Write-BespokeState -Title $title -Installed
                continue
            }

            # Do this in a background job so the 
            $job = Start-Job -ScriptBlock {
                $module = Find-Module -Name $using:pkgMgmtModule | Select-Object -First 1
                if( $module )
                {
                    "$($pkgMgmtModule) [$($module.Version)]" | Write-BespokeState -Title $title -NotInstalled
                    $module | Install-Module -Scope CurrentUser -AllowClobber -Force
                }
                else
                {
                    Write-Error -Message "Module ""$($using:pkgMgmtModule)"" not found."
                }
            }
            $job | Wait-Job | Receive-Job
            $job | Remove-Job

            # So this variable doesn't creep into the process block.
            $module = $null
        }

    }

    process
    {
        $properties = @{
            'version' = '*';
            'repository' = @();
            'scope' = 'CurrentUser';
            'allowPrerelease' = $false;
            'acceptLicense' = $false;
            'skipPublisherCheck' = $false;
            'force' = $false;
            'allowClobber' = $false;
        }

        $package = $InputObject | ConvertTo-BespokeItem -DefaultPropertyName 'name' -Property $properties

        $conditionalFindModuleParams = @{ }
        foreach( $paramName in @('AllowPrerelease', 'Repository') )
        {
            if( $package.$paramName )
            {
                $conditionalFindModuleParams[$paramName] = $package.$paramName
            }
        }

        $module =
            Find-Module -Name $package.name @conditionalFindModuleParams |
            Sort-Object -Property 'Version' -Descending |
            Where-Object 'Version' -Like $package.version |
            Select-Object -First 1

        if( -not $module )
        {
            $versionMsg = ''
            if( $package.version -ne '*' )
            {
                $versionMsg = " with version matching wildcard ""$($package.version)"""
            }

            $repositoryMsg = 'all repositories'
            if( $package.Repository )
            {
                $repositoryMsg = "repository ""$($package.repository)"""
            }

            $prereleaseMsg = ''
            if( $package.allowPrerelease )
            {
                $prereleaseMsg = ' and included prerelease versions'
            }

            $msg = "PowerShell module $($package.name)$($versionMsg) not found. We searched $($repositoryMsg)$($prereleaseMsg)."
            Write-Error -Message $msg
            return
        }

        $msg = "$($module.Name) $($module.Version)"
        if( Get-Module -Name $module.Name -ListAvailable | Where-Object 'Version' -EQ $module.Version )
        {
            $msg | Write-BespokeState -Title $title -Installed
            return
        }

        $installSwitches = @{}
        foreach( $switchName in @('AcceptLicense', 'Force', 'AllowClobber', 'SkipPublisherCheck') )
        {
            if( $package.$switchName )
            {
                $installSwitches[$switchName] = $true
            }
        }
        
        $msg | Write-BespokeState -Title $title -Installed
        $module | Install-Module -Scope $package.scope @installSwitches
    }
}