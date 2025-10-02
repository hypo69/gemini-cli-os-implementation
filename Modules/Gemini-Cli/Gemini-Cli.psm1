# =================================================================================
# ОСНОВНОЙ ФАЙЛ МОДУЛЯ GEMINI-CLI
#
# Описание: Реализация универсального командлета для запуска интерактивного
#           чата с Gemini AI.
# Автор: hypo69
# Версия: 3.7.0 (Возврат к проверенной логике обработки ошибок)
# Дата создания: 02/10/2025
# =================================================================================

#-----------------------------------------------
# Глобальные переменные и внутренние функции модуля
#-----------------------------------------------
$script:GeminiLoggerSettings = @{ Enabled = $false; Path = ""; LogLevel = "INFO" }
$script:LogLevelMap = @{ "DEBUG" = 1; "INFO" = 2; "WARN" = 3; "ERROR" = 4 }

function Write-GeminiLog {
    param(
        [string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")][string]$Level = "INFO",
        [System.Exception]$Exception
    )
    if (-not $script:GeminiLoggerSettings.Enabled) { return }
    if ($script:LogLevelMap[$Level] -lt $script:LogLevelMap[$script:GeminiLoggerSettings.LogLevel]) { return }
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    if ($null -ne $Exception) { $logEntry += "`nException: $($Exception.ToString())" }
    try { Add-Content -Path $script:GeminiLoggerSettings.Path -Value $logEntry -ErrorAction Stop }
    catch { Write-Warning "Не удалось записать лог в файл $($script:GeminiLoggerSettings.Path): $_" }
}

#-----------------------------------------------
# Блок инициализации модуля
#-----------------------------------------------
try {
    $defaultLogPath = "C:\temp\gemini_automation.log"
    $defaultLogDir = Split-Path -Path $defaultLogPath -Parent
    if (-not (Test-Path -Path $defaultLogDir -PathType Container)) {
        New-Item -ItemType Directory -Path $defaultLogDir -Force -ErrorAction Stop | Out-Null
    }
    $script:GeminiLoggerSettings = @{ Enabled = $true; Path = $defaultLogPath; LogLevel = "DEBUG" }
    Write-Host "[Gemini-Cli] Логирование по умолчанию включено. Уровень: DEBUG, Файл: $defaultLogPath"
    Write-GeminiLog -Level "INFO" -Message "Модуль Gemini-Cli загружен. Логгер по умолчанию инициализирован."
} catch {
    Write-Warning "Не удалось инициализировать логгер по умолчанию. Логирование отключено. Ошибка: $_"
    $script:GeminiLoggerSettings.Enabled = $false
}

#-----------------------------------------------
# Публичные функции
#-----------------------------------------------

function Set-GeminiLogger {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'Enable', Mandatory = $true)] [string]$Path,
        [Parameter(ParameterSetName = 'Enable')] [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")] [string]$LogLevel = "INFO",
        [Parameter(ParameterSetName = 'Enable', Mandatory = $true)] [switch]$Enable,
        [Parameter(ParameterSetName = 'Disable', Mandatory = $true)] [switch]$Disable
    )
    if ($Enable) {
        $script:GeminiLoggerSettings = @{ Enabled = $true; Path = $Path; LogLevel = $LogLevel }
        Write-Host "Логирование перенастроено. Уровень: $LogLevel. Файл: $Path"; Write-GeminiLog -Level "INFO" -Message "Логгер перенастроен вручную."
    } elseif ($Disable) {
        Write-GeminiLog -Level "INFO" -Message "Логгер остановлен вручную."; $script:GeminiLoggerSettings.Enabled = $false; Write-Host "Логирование отключено."
    }
}

function Set-GeminiSystemPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$Prompt,
        [string]$Path = (Get-Location).Path
    )
    $geminiDir = Join-Path -Path $Path -ChildPath ".gemini"
    if (-not (Test-Path $geminiDir)) { New-Item -ItemType Directory -Path $geminiDir | Out-Null }
    $filePath = Join-Path -Path $geminiDir -ChildPath "GEMINI.md"
    Write-GeminiLog -Level "INFO" -Message "Установка системного промпта в файле '$filePath'."
    try {
        Set-Content -Path $filePath -Value $Prompt -Encoding UTF8 -ErrorAction Stop
        Write-Host "Системный промпт успешно сохранен в $filePath"
    } catch {
        $errorMessage = "Не удалось записать системный промпт в файл '$filePath'."
        Write-GeminiLog -Level "ERROR" -Message $errorMessage -Exception $_.Exception; throw
    }
}

<#
.SYNOPSIS
    Запускает универсальный интерактивный чат с Gemini AI.
.DESCRIPTION
    Создает полноценную интерактивную сессию для общения с Gemini.
    Приоритет поиска API-ключа: .gemini/.env -> параметр -ApiKey -> $env:GEMINI_API_KEY -> интерактивный ввод.
.EXAMPLE
    # Запустить чат. Ключ будет искаться в .gemini/.env, затем в других местах.
    Start-GeminiChat
#>
function Start-GeminiChat {
    [CmdletBinding()]
    param(
        [ValidateSet('gemini-1.5-flash', 'gemini-1.5-pro')]
        [string]$Model = 'gemini-1.5-flash',
        [string]$SystemPrompt,
        [string]$ApiKey
    )

    # --- Настройка окружения чата ---
    $scriptRoot = Get-Location; $geminiDir = Join-Path $scriptRoot ".gemini"; $effectiveApiKey = $null
    $envFilePath = Join-Path $geminiDir ".env"; if (Test-Path $envFilePath) { try { $envContent = Get-Content -Path $envFilePath -Raw; if ($envContent -match '^\s*GEMINI_API_KEY\s*=\s*"?(.+?)"?\s*$') { $effectiveApiKey = $matches[1].Trim(); Write-GeminiLog -Level "DEBUG" -Message "API-ключ загружен из файла .gemini/.env." } } catch { Write-Warning "Не удалось прочитать файл .env: $($_.Exception.Message)" } }
    if (-not $effectiveApiKey -and $PSBoundParameters.ContainsKey('ApiKey')) { $effectiveApiKey = $ApiKey; Write-GeminiLog -Level "DEBUG" -Message "API-ключ получен из параметра -ApiKey." }
    if (-not $effectiveApiKey -and $env:GEMINI_API_KEY) { $effectiveApiKey = $env:GEMINI_API_KEY; Write-GeminiLog -Level "DEBUG" -Message "API-ключ получен из переменной окружения." }
    if (-not $effectiveApiKey) { Write-Warning "API-ключ Gemini не найден."; Write-Host -NoNewline "`nВведите API-ключ или нажмите Enter, чтобы продолжить без него: "; $userInputKey = Read-Host; if (-not [string]::IsNullOrWhiteSpace($userInputKey)) { $effectiveApiKey = $userInputKey; Write-GeminiLog -Level "DEBUG" -Message "API-ключ получен от пользователя." } else { Write-Host "Продолжаем без API-ключа..." -ForegroundColor Cyan; Write-GeminiLog -Level "DEBUG" -Message "Пользователь продолжил без API-ключа." } }
    if ($effectiveApiKey) { $env:GEMINI_API_KEY = $effectiveApiKey }
    try { Get-Command gemini -ErrorAction Stop | Out-Null } catch { Write-Error "Команда 'gemini' не найдена. Убедитесь, что Gemini CLI установлен и доступен в PATH."; return }

    # --- Внутренние переменные и функции чата ---
    $historyDir = Join-Path $geminiDir ".chat_history"; $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"; $historyFilePath = Join-Path $historyDir "chat_session_$timestamp.jsonl"
    $baseSystemPrompt = ""; if ($PSBoundParameters.ContainsKey('SystemPrompt')) { $baseSystemPrompt = $SystemPrompt } elseif (Test-Path (Join-Path $geminiDir "GEMINI.md")) { $baseSystemPrompt = Get-Content -Path (Join-Path $geminiDir "GEMINI.md") -Raw }
    
    function Add-History { param([string]$UserPrompt, [string]$ModelResponse)
        if (-not (Test-Path $historyDir)) { New-Item -Path $historyDir -ItemType Directory | Out-Null }
        @{ user = $UserPrompt } | ConvertTo-Json -Compress | Add-Content -Path $historyFilePath
        @{ model = $ModelResponse } | ConvertTo-Json -Compress | Add-Content -Path $historyFilePath
    }
    function Show-History {
        if (-not (Test-Path $historyFilePath)) { Write-Host "История текущей сессии пуста." -ForegroundColor Yellow; return }
        Write-Host "`n--- История текущей сессии ---" -ForegroundColor Cyan; Get-Content -Path $historyFilePath; Write-Host "------------------------------------`n" -ForegroundColor Cyan
    }
    function Clear-History {
        if (Test-Path $historyFilePath) { try { Remove-Item -Path $historyFilePath -Force -ErrorAction Stop; Write-Host "История текущей сессии ($($historyFilePath | Split-Path -Leaf)) была удалена." -ForegroundColor Yellow } catch { Write-Warning "Не удалось удалить файл истории: $_" } }
        else { Write-Host "История текущей сессии пуста, удалять нечего." -ForegroundColor Yellow }
    }
    function Show-Help {
        $helpFilePath = Join-Path $geminiDir "ShowHelp.md"; if (Test-Path $helpFilePath) { Get-Content -Path $helpFilePath -Raw | Write-Host } else { Write-Warning "Файл справки .gemini/ShowHelp.md не найден." }
    }
    function Command-Handler { param([string]$Command)
        switch ($Command.ToLower()) {
            '?' { Show-Help; return 'continue' }; 'history' { Show-History; return 'continue' }; ('clear', 'clear-history') { Clear-History; return 'continue' }
            'gemini help' { Write-Host "`n--- Справка Gemini CLI ---`n" -ForegroundColor Cyan; & gemini --help; Write-Host "`n--------------------------`n" -ForegroundColor Cyan; return 'continue' }
            ('exit', 'quit') { return 'break' }; default { return $null }
        }
    }
    
    # ИСПРАВЛЕНО: ИСПОЛЬЗУЕТСЯ ВАША ПРОВЕРЕННАЯ ЛОГИКА ОБРАБОТКИ ОШИБОК
    function Invoke-GeminiPrompt {
        param([string]$Prompt, [string]$Model)
        try {
            $output = & gemini -m $Model -p $Prompt 2>&1
            if (-not $?) {
                $output | ForEach-Object { Write-Warning $_.ToString() }
                return $null
            }
            $outputString = ($output -join [Environment]::NewLine).Trim()
            $cleanedOutput = $outputString -replace "(?m)^Data collection is disabled\.`r?`n" , ""
            $cleanedOutput = $cleanedOutput -replace "(?m)^Loaded cached credentials\.`r?`n", ""
            return $cleanedOutput.Trim()
        }
        catch {
            Write-Error "Критическая ошибка при вызове Gemini CLI: $_"
            return $null
        }
    }

    function Show-SelectionTable { param([array]$SelectedData)
        if ($null -eq $SelectedData -or $SelectedData.Count -eq 0) { return }
        Write-Host "`n--- ВЫБРАННЫЕ ДАННЫЕ ---" -ForegroundColor Yellow; if ($SelectedData -isnot [array]) { $SelectedData = @($SelectedData) }
        $allProperties = @(); foreach ($item in $SelectedData) { if ($item -is [PSCustomObject]) { $properties = $item | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name; $allProperties = $allProperties + $properties | Sort-Object -Unique } }
        if ($allProperties.Count -gt 0) { $SelectedData | Format-Table -Property $allProperties -AutoSize -Wrap }
        else { for ($i = 0; $i -lt $SelectedData.Count; $i++) { Write-Host "[$($i + 1)] $($SelectedData[$i])" -ForegroundColor White } }
        Write-Host "-------------------------" -ForegroundColor Yellow; Write-Host "Выбрано элементов: $($SelectedData.Count)" -ForegroundColor Magenta; Write-Host ""
    }
    
    # --- Основной цикл чата ---
    Write-Host "Интерактивный чат Gemini. Модель: '$Model'." -ForegroundColor Green; Write-Host "Файл сессии будет сохранен в: $historyFilePath" -ForegroundColor Yellow; Write-Host "Введите 'exit' для выхода или '?' для помощи."
    $selectionContextJson = $null 
    while ($true) {
        if ($selectionContextJson) { Write-Host -NoNewline -ForegroundColor Green "🤖AI [Выборка активна] :) > " } else { Write-Host -NoNewline -ForegroundColor Green "🤖AI :) > " }
        $UserPrompt = Read-Host
        $commandResult = Command-Handler -Command $UserPrompt
        if ($commandResult -eq 'break') { break }; if ($commandResult -eq 'continue') { continue }; if ([string]::IsNullOrWhiteSpace($UserPrompt)) { continue }
        Write-Host "Идет обработка запроса..." -ForegroundColor Gray
        $historyContent = if (Test-Path $historyFilePath) { Get-Content -Path $historyFilePath -Raw -ErrorAction SilentlyContinue } else { "" }
        $fullPrompt = ""; if (-not [string]::IsNullOrWhiteSpace($baseSystemPrompt)) { $fullPrompt += "### СИСТЕМНАЯ ИНСТРУКЦИЯ`n$baseSystemPrompt`n`n" }
        if (-not [string]::IsNullOrWhiteSpace($historyContent)) { $fullPrompt += "### ИСТОРИЯ ДИАЛОГА (КОНТЕКСТ)`n$historyContent`n`n" }
        if ($selectionContextJson) { $fullPrompt += "### ДАННЫЕ ИЗ ВЫБОРКИ (ДЛЯ АНАЛИЗА)`n$selectionContextJson`n`n" ; $selectionContextJson = $null }
        $fullPrompt += "### НОВАЯ ЗАДАЧА`n$UserPrompt"
        $ModelResponse = Invoke-GeminiPrompt -Prompt $fullPrompt -Model $Model
        if ($ModelResponse) {
            $jsonToParse = $null; if ($ModelResponse -match '(?s)```json\s*(.*?)\s*```') { $jsonToParse = $matches[1] } else { $jsonToParse = $ModelResponse }
            try {
                $jsonObject = $jsonToParse | ConvertFrom-Json
                Write-Host "`n--- Gemini вернул объект JSON. Открывается интерактивная таблица... ---`n" -ForegroundColor Green
                $gridSelection = $jsonObject | Out-ConsoleGridView -Title "Выберите строки для следующего запроса (OK) или закройте (Cancel)" -OutputMode Multiple
                if ($null -ne $gridSelection) {
                    Show-SelectionTable -SelectedData $gridSelection; $selectionContextJson = $gridSelection | ConvertTo-Json -Compress -Depth 10
                    Write-Host "Выборка сохранена. Добавьте ваш следующий запрос (например, 'сравни их')." -ForegroundColor Magenta
                }
            }
            catch { Write-Host $ModelResponse -ForegroundColor Cyan }
            Add-History -UserPrompt $UserPrompt -ModelResponse $ModelResponse
        }
    }
    Write-Host "Завершение работы." -ForegroundColor Green
}

# Экспортируем все публичные функции
Export-ModuleMember -Function 'Start-GeminiChat', 'Set-GeminiSystemPrompt', 'Set-GeminiLogger'