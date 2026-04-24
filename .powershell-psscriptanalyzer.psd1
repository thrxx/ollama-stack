@{
    IncludeDefaultRules = $true

    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSUseApprovedVerbs',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingInvokeExpression',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseConsistentWhitespace'
    )

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            IndentationSize = 4
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator = $true
            CheckParameter = $true
        }

        PSAvoidTrailingWhitespace = @{
            Enable = $true
        }

        PSUseCorrectCasing = @{
            Enable = $true
        }

        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            Whitelist = @('%', '?', 'where', 'foreach')
        }
    }
}