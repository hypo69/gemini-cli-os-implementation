# =================================================================================
# ОСНОВНОЙ ФАЙЛ МОДУЛЯ GEMINI-CLI
#
# Описание: Реализация командлетов для взаимодействия с Gemini CLI,
#           с автоматическим ведением истории диалогов.
# Автор: hypo69
# Версия: 1.3.2 (Исправлена обработка типов исключений в логгере)
# Дата создания: 02/10/2025
# =================================================================================

#-----------------------------------------------
# Глобальные переменные модуля
#-----------------------------------------------
$script:GeminiLoggerSettings = @{ Enabled = $false; Path = ""; LogLevel = "INFO" }
$script:LogLevelMap = @{ "DEBUG" = 1; "INFO" = 2; "WARN" = 3; "ERROR" = 4 }

# Переменные для управления историей
$script:HistoryEnabled = $true
$script:CurrentHistoryFile = $null


#-----------------------------------------------
# Частная функция для записи логов
#-----------------------------------------------
function Write-GeminiLog {
    param(
        [string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",
        [System.Exception]$Exception
    )

    if (-not $script:GeminiLoggerSettings.Enabled) { return }
    if ($script:LogLevelMap[$Level] -lt $script:LogLevelMap[$script:GeminiLoggerSettings.LogLevel]) { return }

    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"

    if ($null -ne $Exception) { $logEntry += "`nException: $($Exception.ToString())" }

    try {
        Add-Content -Path $script:GeminiLoggerSettings.Path -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Warning "Не удалось записать лог в файл $($script:GeminiLoggerSettings.Path): $_"
    }
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

function New-GeminiSession {
    [CmdletBinding()]
    param()
    Write-Host "Начата новая сессия Gemini. Следующий запрос создаст новый файл истории."
    Write-GeminiLog -Level "INFO" -Message "Сессия сброшена пользователем. Файл истории будет создан заново."
    $script:CurrentHistoryFile = $null
}

function Set-GeminiHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )
    $script:HistoryEnabled = $Enabled
    $status = if ($Enabled) { "включено" } else { "отключено" }
    Write-Host "Ведение истории диалогов $status."
    Write-GeminiLog -Level "INFO" -Message "Ведение истории было $status пользователем."
}

function Set-GeminiLogger {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'Enable', Mandatory = $true)]
        [string]$Path,
        [Parameter(ParameterSetName = 'Enable')]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$LogLevel = "INFO",
        [Parameter(ParameterSetName = 'Enable', Mandatory = $true)]
        [switch]$Enable,
        [Parameter(ParameterSetName = 'Disable', Mandatory = $true)]
        [switch]$Disable
    )

    if ($Enable) {
        $script:GeminiLoggerSettings = @{ Enabled = $true; Path = $Path; LogLevel = $LogLevel }
        Write-Host "Логирование перенастроено. Уровень: $LogLevel. Файл: $Path"
        Write-GeminiLog -Level "INFO" -Message "Логгер перенастроен вручную."
    }
    elseif ($Disable) {
        Write-GeminiLog -Level "INFO" -Message "Логгер остановлен вручную."
        $script:GeminiLoggerSettings.Enabled = $false
        Write-Host "Логирование отключено."
    }
}

function Invoke-Gemini {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        [Parameter()]
        [string]$Model,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$AdditionalArgs
    )

    Write-GeminiLog -Level "INFO" -Message "Запуск Invoke-Gemini..."
    
    if ($script:HistoryEnabled -and ($null -eq $script:CurrentHistoryFile)) {
        try {
            $historyDir = Join-Path -Path (Get-Location).Path -ChildPath ".history"
            if (-not (Test-Path $historyDir)) {
                Write-GeminiLog -Level "INFO" -Message "Создание директории истории: $historyDir"
                New-Item -ItemType Directory -Path $historyDir | Out-Null
            }
            $fileName = "$(Get-Date -Format 'yyyyMMdd_HHmmss').jsonl"
            $script:CurrentHistoryFile = Join-Path -Path $historyDir -ChildPath $fileName
            Write-GeminiLog -Level "INFO" -Message "Новая сессия истории начата. Файл: $($script:CurrentHistoryFile)"
        } catch {
            Write-GeminiLog -Level "WARN" -Message "Не удалось инициализировать историю сессии: $($_.Exception.Message)"
        }
    }

    try {
        if (-not (Get-Command gemini -ErrorAction SilentlyContinue)) { throw "Команда 'gemini' не найдена. Убедитесь, что Gemini CLI установлен и доступен в системном PATH." }
        
        $argumentList = New-Object System.Collections.Generic.List[string]
        if ($PSBoundParameters.ContainsKey('Model')) { $argumentList.Add("--model"); $argumentList.Add($Model) }
        $argumentList.Add("prompt"); $argumentList.Add("`"$Prompt`"")
        if ($null -ne $AdditionalArgs) { $argumentList.AddRange($AdditionalArgs) }
        
        $commandString = "gemini $($argumentList -join ' ')"
        Write-GeminiLog -Level "DEBUG" -Message "Команда: $commandString"

        $process = Start-Process "gemini" -ArgumentList $argumentList -Wait -NoNewWindow -PassThru -RedirectStandardOutput "stdout.tmp" -RedirectStandardError "stderr.tmp"
        $stdout = Get-Content "stdout.tmp" -Raw -ErrorAction SilentlyContinue
        $stderr = Get-Content "stderr.tmp" -Raw -ErrorAction SilentlyContinue
        Remove-Item "stdout.tmp", "stderr.tmp" -ErrorAction SilentlyContinue

        $exitCode = $process.ExitCode
        if ($exitCode -eq 0) {
            Write-GeminiLog -Level "INFO" -Message "Команда Gemini CLI успешно выполнена."
            Write-GeminiLog -Level "DEBUG" -Message "Stdout: $stdout"

            if ($script:HistoryEnabled -and $script:CurrentHistoryFile) {
                try {
                    $userEntry = @{ role = 'user'; content = $Prompt } | ConvertTo-Json -Compress
                    $modelEntry = @{ role = 'model'; content = $stdout } | ConvertTo-Json -Compress
                    Add-Content -Path $script:CurrentHistoryFile -Value $userEntry
                    Add-Content -Path $script:CurrentHistoryFile -Value $modelEntry
                } catch {
                    Write-GeminiLog -Level "WARN" -Message "Не удалось записать в файл истории '$($script:CurrentHistoryFile)': $($_.Exception.Message)"
                }
            }
            return $stdout
        } else {
            $errorMessage = "Gemini CLI завершился с ошибкой (ExitCode: $exitCode). Stderr: $stderr"
            Write-GeminiLog -Level "ERROR" -Message $errorMessage
            throw $errorMessage
        }
    } catch {
        $fatalErrorMessage = "Критическая ошибка при выполнении Invoke-Gemini."
        Write-GeminiLog -Level "ERROR" -Message $fatalErrorMessage -Exception $_.Exception
        throw
    }
}

function Set-GeminiSystemPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        [string]$Path = (Get-Location).Path
    )

    $filePath = Join-Path -Path $Path -ChildPath "GEMINI.md"
    Write-GeminiLog -Level "INFO" -Message "Установка системного промпта в файле '$filePath'."
    try {
        Set-Content -Path $filePath -Value $Prompt -Encoding UTF8 -ErrorAction Stop
        Write-Host "Системный промпт успешно сохранен в $filePath"
    }
    catch {
        $errorMessage = "Не удалось записать системный промпт в файл '$filePath'."
        Write-GeminiLog -Level "ERROR" -Message $errorMessage -Exception $_.Exception
        throw
    }
}

# Экспортируем все публичные функции
Export-ModuleMember -Function 'Invoke-Gemini', 'Set-GeminiSystemPrompt', 'Set-GeminiLogger', 'New-GeminiSession', 'Set-GeminiHistory'