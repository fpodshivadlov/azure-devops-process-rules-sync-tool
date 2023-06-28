Param(
    [Parameter(Mandatory=$true)]
    [string]
    $ConfigurationFilePath,

    [Parameter(Mandatory=$true)]
    [string]
    $Organization,

    [Parameter(Mandatory=$true)]
    [string]
    $ProcessName,

    [Parameter(Mandatory=$true)]
    [string]
    $ProcessId,

    [Parameter(Mandatory=$true)]
    [string]
    $PatToken
)

$ErrorActionPreference = "Stop"

function Format-PatTokenBasicHeader {
    param (
        [Parameter(ValueFromPipeline = $true)][string] $PatToken
    )

    $pair = "{0}:{1}" -f ("", $PatToken)
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $token = [System.Convert]::ToBase64String($bytes)
    "Basic {0}" -f ($token)
}

function Import-HelpersFromPowerShell {
    param (
        [string] $PsFolderPath
    )

    $psFiles = Get-ChildItem -Path $PsFolderPath -Filter "_*.ps1" -Force

    $result = @{}
    foreach ($psFile in $psFiles) {
        Import-Module -Name $psFile.FullName -Force
        $helpersModule = Get-Module -Name $psFile.FullName -ListAvailable

        foreach ($commandName in $helpersModule.ExportedCommands.Keys) {
            $commandObject = $helpersModule.ExportedCommands[$commandName]
            $command = Get-Command $commandObject
            $result[$commandName] = $command.ScriptBlock
        }
    }

    $result
}

Install-Module -Name EPS -Scope CurrentUser

$epsHelpers = Import-HelpersFromPowerShell -PsFolderPath "$PSScriptRoot/templates"

$azureDevOpsHeaders = @{
    Authorization = $PatToken | Format-PatTokenBasicHeader
}

$configurationJson = Get-Content -Path $ConfigurationFilePath | ConvertFrom-Json
$ruleNamePrefix = $configurationJson.Prefix ?? "[sync]"
foreach ($witRefName in $configurationJson.ItemTypes) {
    Write-Host "Processing ""$witRefName"" type..."

    Write-Host "  Requesting list of current rules..."
    $getRulesResponse = Invoke-RestMethod `
        -Uri "https://dev.azure.com/$Organization/_apis/work/processes/$ProcessId/workitemtypes/$Organization$ProcessName.$witRefName/rules?api-version=7.0" `
        -Method GET `
        -Headers $azureDevOpsHeaders
    Write-Debug $getRulesResponse

    $ruleItemsToDelete = $getRulesResponse.value `
        | Where-Object { "$($_.name)".StartsWith("$ruleNamePrefix") }

    Write-Host "  Defining action for rules..."
    $ruleConfigsToSync = @()
    foreach ($ruleConfig in $configurationJson.Rules) {
        $ruleName = "$($ruleNamePrefix) $($ruleConfig.RuleName)";
        $ruleItemType = $ruleConfig.ItemTypes."$witRefName"
        if ($null -eq $ruleItemType) {
            Write-Host "    (skip) $ruleName"
        } else {
            Write-Host "    (sync) $ruleName"
            $ruleConfigsToSync += $ruleConfig
            $ruleItemsToDelete = $ruleItemsToDelete `
                | Where-Object { "$($_.name)" -ne $ruleName }
        }
    }

    Write-Host ""
    foreach ($rule in $ruleItemsToDelete) {
        $ruleId = $rule.id
        $ruleName = $rule.name
        Write-Host "  Working on deleting ""$ruleName"" (id=$ruleId) rule..."

        Invoke-RestMethod `
            -Uri "https://dev.azure.com/$Organization/_apis/work/processes/$ProcessId/workitemtypes/$Organization$ProcessName.$witRefName/rules/$($ruleId)?api-version=7.0" `
            -Method DELETE `
            -Headers $azureDevOpsHeaders

        Write-Host "    the rule is deleted"
    }

    Write-Host ""
    foreach ($ruleConfig in $ruleConfigsToSync) {
        $ruleName = "$($ruleNamePrefix) $($ruleConfig.RuleName)";
        Write-Host "  Working on sync of ""$ruleName"" rule..."

        $templatePath = "$PSScriptRoot/templates/$($ruleConfig.TemplateName)"

        $ruleItemType = $ruleConfig.ItemTypes."$witRefName"
        $sharedProps = $ruleConfig.Props | ConvertTo-Json | ConvertFrom-Json -AsHashTable
        $itemTypeProps = $ruleItemType | ConvertTo-Json | ConvertFrom-Json -AsHashTable
        $props = $sharedProps + $itemTypeProps
        $props["RuleName"] = $ruleName

        $ruleDefinition = Invoke-EpsTemplate -Path $templatePath -Binding $props -Helpers $epsHelpers -Safe
        Write-Verbose $ruleDefinition

        $matchedRule = $getRulesResponse.value | Where-Object { $_.name -eq $ruleName }
        $ruleId = $matchedRule.id
        if ($null -ne $ruleId) {
            Write-Host "    rule (id=$ruleId) already exists, updating"

            Try {
                Invoke-RestMethod `
                    -Uri "https://dev.azure.com/$Organization/_apis/work/processes/$ProcessId/workitemtypes/$Organization$ProcessName.$witRefName/rules/$($ruleId)?api-version=7.0" `
                    -Method PUT `
                    -Headers $azureDevOpsHeaders `
                    -ContentType "application/json" `
                    -Body $ruleDefinition

                Write-Host "    updated"
            } Catch {
                $statusCodeInt = [int]$_.Exception.Response.StatusCode
                if ($statusCodeInt -eq 304) {
                    Write-Host "    not changed"
                } else {
                    throw
                }
            }

            $notSyncedRules = $notSyncedRules | Where-Object { $_.RuleName -ne $ruleName }
        } else {
            Write-Host "    rule does not exists, creating"

            $createRuleResponse = Invoke-RestMethod `
                -Uri "https://dev.azure.com/$Organization/_apis/work/processes/$ProcessId/workitemtypes/$Organization$ProcessName.$witRefName/rules?api-version=7.0" `
                -Method POST `
                -Headers $azureDevOpsHeaders `
                -ContentType "application/json" `
                -Body $ruleDefinition
        
            Write-Host "    created (id=$($createRuleResponse.id))"
        }
    }

    Write-Host ""
    Write-Host ""
}