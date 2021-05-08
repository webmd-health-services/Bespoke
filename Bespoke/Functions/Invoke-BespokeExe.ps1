
function Invoke-BespokeExe
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Path
    )

    Set-StrictMode -Version 'Latest'

    $processName = [IO.Path]::GetFileNameWithoutExtension($Path)
    & $Path
    $exitCode = $LASTEXITCODE
    $exeProcess = Get-Process -Name $processName -ErrorAction Ignore
    if( $exeProcess )
    {
        $exeProcess.Handle | Out-Null
        $exeProcess.WaitForExit()
        $exitCode = $exeProcess.ExitCode
    }

    if( $exitCode )
    {
        $msg = "Executable ""$($Path | Split-Path -Leaf)"" returned non-zero exit code " +
                """$($exitCode)""."
        Write-Error -Message $msg
    }
}