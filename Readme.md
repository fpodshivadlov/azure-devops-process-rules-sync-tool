# Azure Devops Process Rules sync tool

This tool enables you to store Azure DevOps Process Rules under source control.

## Overview

- Consolidates all process rules configurations in a single file
- Enables to share rule defininions between different work item types
- Resolves changes and removes outdated/renamed rules
- Tracks items started with prefix (`[sync]` by default).
  You can continue use manual rules named without this prefix.

## Getting Started

- Install Required modules:
  `Install-Module -Name EPS -Repository PSGallery -Force`
- Review  `/configuration/Standard.json` file and define your own process based on it.
- Add your own templates if the current set of templates does not meet your needs.
- Add your own helpers to simplify template creation if necessary.
- Generate [a PAT token](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows#create-a-pat)
- Run the following PowerShell command to start sync process:
  ```powershell
  & ".\Sync-AzureDevopsProcessRules.ps1" `
      -ConfigurationFilePath "./configuration/CustomProcess.json" `
      -Organization "<target-organization>" `
      -ProcessName "<process-name>" `
      -ProcessId "<process-id>" `
      -PatToken "<PAT-token>"
  ```
  *Note: You can find the Process ID in your browser's developer tools under the Network tab by filtering requests with the https://dev.azure.com/EPMC-STC/_apis/work/processes/ URL.*
