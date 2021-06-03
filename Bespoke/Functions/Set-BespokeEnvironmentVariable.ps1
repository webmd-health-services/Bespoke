
function Set-BespokeEnvironmentVariable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]$InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $property = @{
            'scope' = 'User';
            'vars' = [pscustomobject]@{};
            'listVars' = @();
            'listSeparator' = [IO.Path]::PathSeparator;
            'append' = $true;
            'expandEnvironmentNames' = $false;
        }
        $item = $InputObject | ConvertTo-BespokeItem -Property $property

        $envVars = $item.vars | ConvertTo-BespokeItem

        $listVars = & {
                'Path'
                'PSModulePath'
                'PATHEXT'
                $item.listVars
            } | 
            Select-Object -Unique

        foreach( $name in ($envVars | Get-Member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name') )
        {
            $value = $envVars.$name
            $regPath = 'HKCU:\Environment'
            if( $item.scope -eq 'Machine' )
            {
                $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
            }

            $envReg = Get-Item -Path $regPath
            
            # Don't do expando magic.
            $currentValue = $envReg.GetValue($name, '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            if( $name -in $listVars )
            {
                $value = & {
                        if( -not $item.append )
                        {
                            $value
                        }
                        $currentValue -split $item.listSeparator
                        if( $item.append )
                        {
                            $value
                        }
                    } |
                    Select-Object -Unique
                $value = $value -join $item.listSeparator
            }

            $msg = "$($name)  $($envVars.$name)"

            if( $currentValue -eq $value )
            {
                $msg | Write-BespokeState -Title 'Environment Variables' -Installed
                continue
            }

            $msg | Write-BespokeState -Title 'Environment Variables' -NotInstalled
            
            $expandParam = @{}
            if( $item.expandEnvironmentNames )
            {
                $expandParam['Expand'] = $true
            }
            Set-CRegistryItem -Path $regPath -Name $name -String $value @expandParam
        }
    }
}