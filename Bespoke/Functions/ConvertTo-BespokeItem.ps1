
function ConvertTo-BespokeItem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject,

        [String]$DefaultPropertyName,

        [hashtable]$Property = @{}
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        
        Write-Debug "[ConvertTo-BespokeItem]  InputObject  [$($InputObject.GetType().Name)]"
        if( $InputObject -is [String] -or $InputObject -is [int] -or $InputObject -is [bool] -or $InputObject -is [DateTime] )
        {
            if( $DefaultPropertyName )
            {
                $InputObject = [pscustomobject]@{
                    $DefaultPropertyName = $InputObject;
                }
            }
            else
            {
                $msg = "Error with bespoke configuration item ""$($InputObject)"". Received a " +
                       "[$($InputObject.GetType().Name)] but expected an object with some combination of these " +
                       "properties: $($Property.Keys -join ", ")."
                Write-Error -Message $msg
                return
            }
        }

        foreach( $propertyName in $Property.Keys )
        {
            if( $InputObject | Get-Member $propertyName )
            {
                continue
            }

            $InputObject |
                Add-Member -Name $propertyName -MemberType NoteProperty -Value $Property[$propertyName]
        }

        $propertyNames = $InputObject | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty 'Name'
        foreach( $propertyName in $propertyNames )
        {
            $value = $InputObject.$propertyName
            while( $value -match '~([^~]+?)~' )
            {
                $specialFolderName = $Matches[1]
                $replacement = [Environment]::GetFolderPath($specialFolderName)
                if( -not $replacement )
                {
                    $msg = "Special folder ""$($specialFolderName)"" is not available on this system."
                    Write-Warning -Message $msg
                    break
                }
                $value = $value -replace "~$([regex]::Escape($specialFolderName))~", $replacement
            }
            $InputObject.$propertyName = $value
        }

        return $InputObject
    }
}