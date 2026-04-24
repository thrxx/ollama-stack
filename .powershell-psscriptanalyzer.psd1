@{
    IncludeDefaultRules = $true
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSUseApprovedVerbs',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingEmptyCatchBlock',      # ← Добавьте это
        'PSUseBOMForUnicodeEncodedFile',    # ← И это
        'PSAvoidUsingInvokeExpression',
        'PSUseBOMForUnicodeEncodedFile'
    )
}