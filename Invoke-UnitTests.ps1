#Requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.4.0" }

param (
    [string] $CodeCoverageOutputFormat = "JaCoCo"
)

$ErrorActionPreference = "Stop"

$config = [PesterConfiguration]::Default
$config.Run.Path = "$PSScriptRoot"
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$PSScriptRoot/output/testResults.xml"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.OutputFormat = $CodeCoverageOutputFormat
$config.CodeCoverage.OutputPath = "$PSScriptRoot/output/coverage.xml"
$config.CodeCoverage.Path = @(
    "$PSScriptRoot/Sync-AzureDevopsProcessRules.ps1"
)

Invoke-Pester -Configuration $config
