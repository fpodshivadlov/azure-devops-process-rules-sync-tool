$ErrorActionPreference = "Stop"

Import-Module Pester -MinimumVersion "5.4.0"

$config = [PesterConfiguration]::Default
$config.Run.Path = "$PSScriptRoot"
$config.TestResult.Enabled = $true
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @(
    "$PSScriptRoot/Sync-AzureDevopsProcessRules.ps1"
)

Invoke-Pester -Configuration $config
