# --- Invoke-Gemini ---
function Invoke-Gemini {
    <#
    .SYNOPSIS
        Выполняет запрос к Gemini CLI.
    .DESCRIPTION
        Обертка над gemini-cli для вызова прямо из PowerShell.
    .PARAMETER Prompt
        Текстовый запрос к модели Gemini.
    .PARAMETER Model
        Модель Gemini (например, gemini-2.5-pro).
    .PARAMETER Args
        Дополнительные параметры для gemini-cli (например, --json).
    .EXAMPLE
        Invoke-Gemini -Prompt "Explain quantum computing"
    .EXAMPLE
        Invoke-Gemini -Prompt "Summarize AI news" -Model "gemini-2.5-flash" -Args "--json"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [string]$Model = "gemini-2.5-flash",

        [string[]]$Args
    )

    $cmd = "gemini"
    $allArgs = @(
        "-m", $Model,
        "-p", "`"$Prompt`""   # оборачиваем промпт в кавычки
    ) + $Args

    & $cmd @allArgs
}
