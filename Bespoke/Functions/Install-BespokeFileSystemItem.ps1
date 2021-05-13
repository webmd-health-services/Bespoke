
function Install-BespokeFileSystemItem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]$InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Write-Information 'File System'
    }

    process
    {
        $properties = @{
            'path' = ''; 
            'type' = '';
            'link' = '';
            'target' = '';
            'invoke' = $false;
        }
        $item = $InputObject | ConvertTo-BespokeItem -Property $properties

        if( -not ($item | Get-Member -Name 'type') )
        {
            $msg = "File system items must have a ""type"" property that must be one of: File, Directory, or HardLink."
            Write-Error -Message $msg
            return
        }

        if( $item.type -in @('File', 'Directory') )
        {
            if( -not $item.path )
            {
                $msg = "$($item.type) items must have a ""path"" property that is the path to the " +
                       "$($item.type.ToLowerInvariant()) to create."
                Write-Error -Message $msg
                return
            }
    
            if( (Test-Path -Path $item.path) )
            {
                Write-Information "      $($item.path)"
                return
            }

            Write-Information "    + $($item.path)"
            New-Item -Path $item.Path -ItemType $item.type | Out-Null
            return
        }

        if( $item.type -eq 'HardLink' )
        {
            if( -not $item.link )
            {
                $msg = 'Hard link items must have a ""link"" property that is the path to the new file that will be ' +
                       'linked to a target file.'
                Write-Error -Message $msg
                return
            }

            if( -not $item.target )
            {
                $msg = 'Hard link items must have a ""target"" property that is the target path that the link path ' +
                       'will point to.'
                Write-Error -Message $msg
                return
            }

            $linkPath = $item.link
            
            $targetPath = $item.target | Resolve-Path | Select-Object -ExpandProperty 'ProviderPath'
            if( -not $targetPath )
            {
                return
            }

            if( (Test-Path -Path $linkPath) )
            {
                $destItem = Get-Item -Path $linkPath
                if( -not ($destItem | Get-Member 'Target') )
                {
                    $msg = 'Unable to create hard links on this file system.'
                    Write-Error -Message $msg
                    return
                }

                if( $destItem.LinkType -ne 'HardLink' )
                {
                    $msg = "Unable to hard link ""$($linkPath)"" to ""$($targetPath)"": ""$($linkPath)"" exists and " +
                           'is not a hard link.'
                    Write-Error -Message $msg
                    return
                }

                if( $destItem.Target -contains $targetPath )
                {
                    Write-Information "      $($linkPath)"
                    return
                }

                Remove-Item -Path $linkPath
            }

            Write-Information "    + $($linkPath)"
            New-Item -ItemType 'HardLink' -Path $linkPath -Target $targetPath | Out-Null
        }
    }
}