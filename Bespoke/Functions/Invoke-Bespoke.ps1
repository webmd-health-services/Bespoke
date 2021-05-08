
function Invoke-Bespoke
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Git')]
        [String]$BespokeType,

        [Parameter(Mandatory)]
        # The url to the Git repository containing your Bespoke configuration. This will be cloned to "your home 
        # directory in a ".bespoke" directory.
        [Uri]$Url
    )

    Set-StrictMode -Version 'Latest'
    $InformationPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'

    if( -not (Test-Path -Path $cachePath) )
    {
        New-Item -Path $cachePath -ItemType 'Directory' -Force | Out-Null
    }

    $bespokeRoot =
        Join-Path -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)) -ChildPath '.bespoke'

    if( $BespokeType -eq 'Git' )
    {
        if( -not (Get-Command -Name 'git' -ErrorAction Ignore) )
        {
            if( (Get-Command -Name 'winget' -ErrorActionIgnore) -or $IsWindows )
            {
                Install-Winget 
                winget install --id 'Git.Git'
            }
            elseif( (Get-Command -Name 'apt-get' -ErrorAction Ignore) )
            {
                apt-get install 'git'
            }
            elseif( (Get-Command -Name 'brew' -ErrorAction Ignore) )
            {
                brew install 'git'
            }
            else
            {
                $msg = 'Git isn''t installed (or isn''t in your PATH). We can automatically install Git if one of ' + 
                       'the following package managers is installed:' + [Environment]::NewLine +
                       ' ' + [Environment]::NewLine +
                       ' * winget (Windows)' + [Environment]::NewLine +
                       ' * apt-get (Linux)' + [Environment]::NewLine +
                       ' * brew (macOS)'
                Write-Error -Message $msg
                return
            }

            if( -not (Get-Command -Name 'git' -ErrorAction Ignore) )
            {
                Write-Warning 'We installed Git but isn''t in your path. Restart PowerShell.'
                exit
            }
        }

        $doGitPull = $true
        if( -not (Test-Path -Path $bespokeRoot) )
        {
            Write-Information "Cloning your bespoke repository ""$($Url)"" to ""$($bespokeRoot)""."
            git clone $Url $bespokeRoot
            $doGitPull = $false
        }

        if( -not (Test-Path -Path (Join-Path -Path $bespokeRoot -ChildPath '.git') -PathType Container) ) 
        {
            $msg = "Your Bespoke directory, ""$($bespokeRoot)"", isn't a Git repository. Please set aside this "
                   'directory and re-run bespoke.'
            Write-Error -Message $msg -ErrorAction Stop
        }

        if( $doGitPull )
        {
            Push-Location $bespokeRoot
            try
            {
                $msg = "Pulling latest changes into your local bespoke repository ""$($bespokeRoot)""."
                Write-Information -Message $msg
                git pull
            }
            finally
            {
                Pop-Location
            }    
        }
    }

    $bespokeConfigPath = Join-Path -Path $bespokeRoot -ChildPath 'bespoke.json'
    if( -not (Test-Path -Path $bespokeConfigPath) )
    {
        $msg = "Nothing to do. You're missing a $($bespokeConfigPath) file. See the Bespoke README.md for documentation."
        Write-Warning -Message $msg
        return
    }

    $bespokeConfig = Get-Content -Path $bespokeConfigPath | ConvertFrom-Json

    if( $bespokeConfig | Get-Member 'packages' )
    {
        $packagesConfig = $bespokeConfig.packages
        if( $IsWindows -and ($packagesConfig | Get-Member 'winget') )
        {
            $packagesConfig.winget | Where-Object { Test-BespokeItem $_ } | Install-WingetPackage
        }

        if( $packagesConfig | Get-Member 'powershellModules' )
        {
            $packagesConfig.powershellModules | Where-Object { Test-BespokeItem $_ } | Install-PowerShellModule
        }

        if( $packagesConfig | Get-Member -Name 'appx' )
        {
            $packagesConfig.appx | Where-Object { Test-BespokeItem $_ } | Install-AppxPackage
        }
    
        if( $packagesConfig | Get-Member -Name 'zip' )
        {
            $packagesConfig.zip | Where-Object { Test-BespokeItem $_ } | Install-ZipFile
        }

        if( $packagesConfig | Get-Member -Name 'exe' )
        {
            $packagesConfig.exe | Where-Object { Test-BespokeItem $_ } | Install-BespokeExe
        }
    }

    if( $bespokeConfig | Get-Member -Name 'profiles' )
    {
        $bespokeConfig.profiles | Where-Object { Test-BespokeItem $_ } | Install-ShellProfile
    }

    $userInitPath = Join-Path -Path $bespokeRoot -ChildPath 'init.ps1'
    if( (Test-Path -Path $userInitPath) )
    {
        Write-Information ($userInitPath | Resolve-Path -Relative)
        & $userInitPath
    }
}