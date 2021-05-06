
function Install-Winget
{
    if( -not (Get-Command -Name 'winget' -ErrorAction Ignore) )
    {
        Write-Information 'Installing winget.'
        [Uri]$winGetBundleUrl = 'https://github.com/microsoft/winget-cli/releases/download/v-0.3.11102-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle'
        $winGetBundlePath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath $winGetBundleUrl.Segments[-1]
        Save-BespokeUrl -url $winGetBundleUrl -Checksum '5867992f57b92aa4662829e6bacd77ed70f59198edfe976cc3cf2384652652c84217670878d56b4774082e7dd33f49445e7483204ae1a420403852ff6d1b4eb3'
        Add-AppxPackage -Path $winGetBundlePath

        if( -not (Get-Command -Name 'winget' -ErrorAction Ignore) )
        {
            $msg = 'Winget installed but not found in your PATH. Please restart your PowerShells session.'
            Write-Error -Message $msg -ErrorAction Stop
        }
    }

    function Initialize-WingetSettingsFile
    {
        @'
    {
        "$schema": "https://aka.ms/winget-settings.schema.json"
    }
'@ | Set-Content -Path $wingetSettingsPath
    }

    function Import-WingetSetting
    {
        try
        {
            Get-Content -Path $wingetSettingsPath | ConvertFrom-Json -ErrorAction Ignore
        }
        catch 
        {
            Initialize-WingetSettingsFile
            Import-WingetSetting
        }
    }

    $wingetSettingsPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json'
    if( -not (Test-Path -Path $wingetSettingsPath -PathType Leaf) )
    {
        Initialize-WingetSettingsFile
    }

    $wingetSettings = Import-WingetSetting

    $wingetSettings | 
        Add-Member -Name 'experimentalFeatures' -MemberType NoteProperty -Value ([pscustomobject]@{}) -ErrorAction Ignore
    $wingetSettings.experimentalFeatures |
        Add-Member -Name 'list' -MemberType NoteProperty -Value $true -ErrorAction Ignore
    $wingetSettings.experimentalFeatures.list = $true
    $wingetSettings | ConvertTo-Json -Depth 100 | Set-Content -Path $wingetSettingsPath
}