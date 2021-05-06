
function ConvertTo-BespokeItem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Object]$InputObject,

        [String]$DefaultPropertyName,

        [hashtable]$Property
    )

    process
    {
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

            $InputObject | Add-Member -Name $propertyName -MemberType NoteProperty -Value $Property[$propertyName]
        }

        return $InputObject
    }
}