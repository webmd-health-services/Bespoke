
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

function GivenModuleLoaded
{
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Bespoke\Bespoke.psd1' -Resolve)
    Get-Module -Name 'Bespoke' | Add-Member -MemberType NoteProperty -Name 'NotReloaded' -Value $true
}

function GivenModuleNotLoaded
{
    Remove-Module -Name 'Bespoke' -Force -ErrorAction Ignore
}

function Init
{

}

function ThenModuleLoaded
{
    $module = Get-Module -Name 'Bespoke'
    $module | Should -Not -BeNullOrEmpty
    $module | Get-Member -Name 'NotReloaded' | Should -BeNullOrEmpty
}

function WhenImporting
{
    $script:importedAt = Get-Date
    Start-Sleep -Milliseconds 1
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Bespoke\Import-Bespoke.ps1' -Resolve)
}

Describe 'Import-Bespoke.when module not loaded' {
    It 'should import the module' {
        Init
        GivenModuleNotLoaded
        WhenImporting
        ThenModuleLoaded
    }
}

Describe 'Import-Bespoke.when module loaded' {
    It 'should re-import the module' {
        Init
        GivenModuleLoaded
        WhenImporting
        ThenModuleLoaded
    }
}
