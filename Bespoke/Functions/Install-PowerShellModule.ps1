
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

        Write-Information 'PowerShell Modules'

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
                Write-Information "      $($module.Name) $($module.Version)"
                continue
            }

            # Do this in a background job so the 
            $job = Start-Job -ScriptBlock {
                $module = Find-Module -Name $using:pkgMgmtModule | Select-Object -First 1
                if( $module )
                {
                    Write-Information "    + $($pkgMgmtModule) [$($module.Version)]"
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

        if( Get-Module -Name $module.Name -ListAvailable | Where-Object 'Version' -EQ $module.Version )
        {
            Write-Information "      $($module.Name) $($module.Version)"
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
        
        Write-Information "    + $($module.Name) $($module.Version)"
        $module | Install-Module -Scope $package.scope @installSwitches
    }
}