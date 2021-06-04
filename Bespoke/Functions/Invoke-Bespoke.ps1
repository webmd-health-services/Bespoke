
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
        [Uri]$Url,

        [String[]]$Include
    )

    Set-StrictMode -Version 'Latest'
    $InformationPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'

    $script:lastStateMsgTitle = ''
    if( -not $Include )
    {
        $Include = @()
    }

    foreach( $dataPath in @($cachePath, $tempPath) )
    {
        if( -not (Test-Path -Path $dataPath) )
        {
            New-Item -Path $dataPath -ItemType 'Directory' -Force | Out-Null
        }    
    }

    Get-ChildItem -Path $tempPath | Remove-Item -Recurse -Force -ErrorAction Ignore

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

    Push-Location -Path $bespokeRoot
    $originalPwd = [IO.Directory]::GetCurrentDirectory()
    [IO.Directory]::SetCurrentDirectory($bespokeRoot)
    try
    {
        $bespokeConfigPath = Join-Path -Path $bespokeRoot -ChildPath 'bespoke.json'
        if( -not (Test-Path -Path $bespokeConfigPath) )
        {
            $msg = "Nothing to do. You're missing a $($bespokeConfigPath) file. See the Bespoke README.md for documentation."
            Write-Warning -Message $msg
            return
        }

        $bespokeCmds = [ordered]@{
            'fileSystem' = 'Install-BespokeFileSystemItem';
            'env' = 'Set-BespokeEnvironmentVariable';
            'winget' = 'Install-WingetPackage';
            'appx' = 'Install-AppxPackage';
            'msi' = 'Install-BespokeMsi';
            'powershellModules' = 'Install-PowerShellModule';
            'zip' = 'Install-BespokeZipFile';
            'font' = 'Install-BespokeFont';
            'profile' = 'Install-ShellProfile';
        }

        $labels = @{
            'fileSystem' = 'File System';
            'env' = 'Environment Variables';
            'msi' = 'MSI';
            'powershellModules' = 'PowerShell Modules';
            'zip' = 'ZIP';
        }

        $bespokeConfig = Get-Content -Path $bespokeConfigPath | ConvertFrom-Json

        foreach( $name in $bespokeCmds.Keys )
        {
            $cmdName = $bespokeCmds[$name]

            if( -not $Include )
            {
                $Include = @()
            }
        
            if( -not ($bespokeConfig | Get-Member -Name $name) -or `
                     ($Include -and $Include -notcontains $name) )
            {
                Write-Debug "Skipping ""$($name)""."
                continue
            }
    
            $config = $bespokeConfig.$name
            if( -not ($config | Test-BespokeItem) )
            {
                continue
            }

            $msg = $labels[$name]
            if( -not $msg )
            {
                $msg = $name.Substring(0,1).ToUpper() + $name.Substring(1)
            }
            $msg = "  [$($msg)]"

            Write-Information $msg
            try
            {
                $config | & $cmdName
            }
            finally
            {
                Write-Information $msg
            }
        }

        $userInitPath = Join-Path -Path $bespokeRoot -ChildPath 'init.ps1'
        if( (Test-Path -Path $userInitPath) )
        {
            Write-Information ($userInitPath | Resolve-Path -Relative)
            & $userInitPath
        }
    }
    finally
    {
        [IO.Directory]::SetCurrentDirectory($originalPwd)
        Pop-Location
    }
}