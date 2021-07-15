
function Write-BespokeState
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Position=0)]
        [String]$Message,

        [Parameter(Mandatory)]
        [String]$Title,

        [String]$Subtitle,

        [int]$SubtitleWidth,

        [int]$IndentLevel = 0,

        [Parameter(Mandatory, ParameterSetName='   ')]
        [switch]$Installed,

        [Parameter(Mandatory, ParameterSetName=' + ')]
        [switch]$NotInstalled
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        if( $PSBoundParameters.ContainsKey('Subtitle') )
        {
            if( $SubtitleWidth )
            {
                $Subtitle = "{0,-$($SubtitleWidth)}" -f $Subtitle
            }
            $Subtitle = "  $Subtitle"
        }
        else
        {
            $Subtitle = ''
        }
    }

    process
    {
        Write-Information "$($PSCmdlet.ParameterSetName)[$($Title)]$($Subtitle)  $('  ' * $IndentLevel)$($Message)"
    }
}