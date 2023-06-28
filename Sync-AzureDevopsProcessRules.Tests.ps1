BeforeAll {
    Mock -CommandName Invoke-RestMethod `
        -MockWith { throw "Mock not defined: $($PesterBoundParameters | ConvertTo-Json)" }

    $DefaultParams = @{
        Organization = "origanization"
        ProcessName = "Agile"
        ProcessId = "00000000-0000-0000-0000-0000000000000"
        PatToken = "pat-token"
        Verbose = $true
    }

    function Throw-InvokeRestException {
        param (
            [string] $Message,
            [System.Net.HttpStatusCode] $HttpStatusCode
        )

        $WebResponse = New-MockObject -Type 'System.Net.HttpWebResponse'
        $WebResponse | Add-Member -MemberType NoteProperty -Name StatusCode -Value $HttpStatusCode -Force
        $Status = [System.Net.WebExceptionStatus]::ProtocolError
        $WebException = [System.Net.WebException]::new($Message, $null, $Status, $WebResponse)
        throw $WebException
    }
}

Describe 'Sync-AzureDevopsProcessRules' {
    It 'Should throw error when configuration file does not exists' {
        $ShouldThrowParams = @{
            ExceptionType = [System.Management.Automation.ItemNotFoundException]
        }

        { 
            & "$PSScriptRoot/Sync-AzureDevopsProcessRules" `
                -ConfigurationFilePath "$PSScriptRoot/NotExistingFile.json" `
                @DefaultParams
        } | Should -Throw @ShouldThrowParams
    }

    It 'Should not update anything when no rules are defined' {
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/get/no-items.json" | ConvertFrom-Json }

        & "$PSScriptRoot/Sync-AzureDevopsProcessRules" `
            -ConfigurationFilePath "$PSScriptRoot/mock/configuration/no-rules.json" `
            @DefaultParams

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' }
    }

    It 'Should not update anything when no rules are defined for the item type' {
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/get/no-items.json" | ConvertFrom-Json }

        & "$PSScriptRoot/Sync-AzureDevopsProcessRules" `
            -ConfigurationFilePath "$PSScriptRoot/mock/configuration/another-item-type-rule.json" `
            @DefaultParams

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' }
    }

    It 'Should not remove rule when prefix is not the same' {
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/get/another-prefix-rules.json" | ConvertFrom-Json }

        & "$PSScriptRoot/Sync-AzureDevopsProcessRules" `
            -ConfigurationFilePath "$PSScriptRoot/mock/configuration/no-rules.json" `
            @DefaultParams

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' }
    }

    It 'Should create rule when the rules is defined' {
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/get/no-items.json" | ConvertFrom-Json }
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Post' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/post/simple-rule.json" | ConvertFrom-Json }

        & "$PSScriptRoot/Sync-AzureDevopsProcessRules" `
            -ConfigurationFilePath "$PSScriptRoot/mock/configuration/simple-rule.json" `
            @DefaultParams

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' }
        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Post' }
    }

    It 'Should delete rule when no rules are defined' {
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/get/one-simple-rule.json" | ConvertFrom-Json }
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Delete' } `
            -MockWith { }

        & "$PSScriptRoot/Sync-AzureDevopsProcessRules" `
            -ConfigurationFilePath "$PSScriptRoot/mock/configuration/no-rules.json" `
            @DefaultParams

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' }
        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Delete' }
    }

    It 'Should update rule if the rule exists' {
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/get/one-simple-rule.json" | ConvertFrom-Json }
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Put' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/post/simple-rule.json" | ConvertFrom-Json }

        & "$PSScriptRoot/Sync-AzureDevopsProcessRules" `
            -ConfigurationFilePath "$PSScriptRoot/mock/configuration/simple-rule.json" `
            @DefaultParams

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' }
        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Put' }
    }

    It 'Should not change rule support when it is not changed' {
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' } `
            -MockWith { Get-Content -Raw -Path "$PSScriptRoot/mock/response-body/get/one-simple-rule.json" | ConvertFrom-Json }
        Mock -CommandName Invoke-RestMethod `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Put' } `
            -MockWith { Throw-InvokeRestException -Message "Not modified" -HttpStatusCode NotModified }

        & "$PSScriptRoot/Sync-AzureDevopsProcessRules" `
            -ConfigurationFilePath "$PSScriptRoot/mock/configuration/simple-rule.json" `
            @DefaultParams

        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Get' }
        Should -Invoke -CommandName Invoke-RestMethod -Exactly -Times 1 `
            -ParameterFilter { $PesterBoundParameters.Method -eq 'Put' }
    }
}