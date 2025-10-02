# =================================================================================
# МАНИФЕСТ МОДУЛЯ GEMINI-CLI
#
# Описание: Метаданные для универсального PowerShell-модуля, предоставляющего
#           мощный интерактивный чат с Gemini AI.
# Автор: hypo69
# Версия: 3.7
# Дата создания: 02/10/2025
# =================================================================================

@{
    RootModule = 'Gemini-Cli.psm1'
    ModuleVersion = '3.7.0'
    GUID = '8c8b5d9e-f21d-4c42-bb34-9d9f33b9a11d'
    Author = 'hypo69'
    CompanyName = 'OpenSource'
    PowerShellVersion = '7.0'
    Description = 'Универсальный модуль для Google Gemini CLI. Предоставляет интерактивный чат с надежной обработкой ошибок, основанной на проверенной логике.'
    FunctionsToExport = @(
        'Start-GeminiChat',
        'Set-GeminiSystemPrompt',
        'Set-GeminiLogger'
    )
}