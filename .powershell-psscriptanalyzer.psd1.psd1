@{
    # Включаем стандартный набор правил Microsoft
    IncludeDefaultRules = $true

    # Исключаем правила, которые конфликтуют с архитектурой ваших скриптов
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',               # ✅ CLI-скрипты намеренно используют Write-Host для цветного вывода
        'PSUseApprovedVerbs',                  # ✅ Вспомогательные функции (Write-Step, Write-OK и т.д.) используют кастомные глаголы
        'PSUseShouldProcessForStateChangingFunctions', # ✅ Скрипты установки/диагностики не требуют -Confirm/-WhatIf
        'PSUseDeclaredVarsMoreThanAssignments', # ✅ Ложные срабатывания в param() и сложных пайплайнах
        'PSAvoidUsingEmptyCatchBlock'          # ✅ Пустые catch {} используются намеренно для некритичных проверок (версии, опц. параметры)
    )

    # Тонкая настройка включённых правил
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
            # Если в будущем добавите % или ? в пайплайны, раскомментируйте:
            # Whitelist = @('%', '?')
        }
    }
}