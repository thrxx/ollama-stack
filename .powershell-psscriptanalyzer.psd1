@{
    # Включаем стандартные правила Microsoft
    IncludeDefaultRules = $true

    # Исключаем правила, которые не подходят для CLI-скриптов
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',               # CLI-скрипты намеренно используют Write-Host для цветного вывода
        'PSUseApprovedVerbs',                  # Вспомогательные функции используют кастомные глаголы (Write-Step, Write-OK)
        'PSUseShouldProcessForStateChangingFunctions', # Скрипты установки не требуют -Confirm/-WhatIf
        'PSUseDeclaredVarsMoreThanAssignments', # Ложные срабатывания в param() и пайплайнах
        'PSAvoidUsingEmptyCatchBlock',         # Пустые catch {} используются намеренно для некритичных проверок
        'PSAvoidUsingInvokeExpression',        # Иногда необходим для динамического кода
        'PSUseBOMForUnicodeEncodedFile'        # Не требуем BOM для UTF-8
    )

    # Тонкая настройка правил
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
            # Разрешаем короткие алиасы в пайплайнах
            Whitelist = @('%', '?', 'where', 'foreach')
        }
    }
}