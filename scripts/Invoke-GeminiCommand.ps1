# =================================================================================
# ИНСТРУМЕНТ ДЛЯ АВТОМАТИЗИРОВАННОГО ЗАПУСКА GEMINI CLI
# PowerShell >= 7.2 (для корректной работы с pwsh.exe)
# Требует предварительной настройки и аутентификации gemini CLI.
# Версия: 1.0 (Оркестратор)
# Автор: hypo69 (на основе обсуждения)
# Дата создания: 18/08/2025 
# =================================================================================
# =================================================================================
# ЛИЦЕНЗИЯ (MIT)
# =================================================================================
<#
Copyright (c) 2025 hypo69

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>
<#
.SYNOPSIS
    Надежно вызывает gemini.ps1 и передает ему аргументы для выполнения.

.DESCRIPTION
    Этот скрипт служит "оберткой" для gemini.ps1, позволяя запускать его из систем
    автоматизации (например, MCP). Он правильно формирует и передает аргументы,
    а также анализирует код завершения ($LASTEXITCODE) для определения
    успешности операции и возвращает соответствующий код выхода (0 или 1).

.PARAMETER GeminiArguments
    Массив всех аргументов, которые нужно передать в gemini.ps1.
    Например: '/mcp', 'run', '--script', 'C:\Scripts\MyTask.ps1'

.EXAMPLE
    # Пример вызова для запуска другого PowerShell-скрипта через gemini
    .\Invoke-GeminiCommand.ps1 -GeminiArguments '/mcp', 'run', '--script', 'C:\Scripts\MyTask.ps1'

.EXAMPLE
    # Пример вызова для получения статуса задачи
    .\Invoke-GeminiCommand.ps1 -GeminiArguments '/mcp', 'status', '--job-id', '12345'

.NOTES
    Скрипт предполагает, что gemini CLI (gemini.ps1) установлен и доступен
    через системную переменную PATH.
    Предназначен для неинтерактивного выполнения.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Укажите массив аргументов для передачи в gemini.ps1")]
    [string[]]$GeminiArguments
)