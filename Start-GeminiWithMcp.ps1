# =================================================================================
# ЗАПУСК GEMINI CLI ДЛЯ РАБОТЫ С ПРЕДВАРИТЕЛЬНО ЗАПУЩЕННЫМ MCP-СЕРВЕРОМ
# =================================================================================

# --- ПРОВЕРКИ ---
if (-not (Get-Command gemini -ErrorAction SilentlyContinue)) {
    Write-Error "Команда 'gemini' не найдена."
    return
}
$configFile = Join-Path (Get-Location) ".gemini\settings.json"
if (-not (Test-Path $configFile)) {
    Write-Error "Файл '$configFile' не найден."
    return
}

# --- ЗАПУСК ---
Write-Host "Запуск Gemini CLI..." -ForegroundColor Cyan
Write-Host "Предполагается, что MCP-сервер уже запущен в отдельном окне."

try {
    # Запускаем gemini. Он сам найдет и прочитает ваш .gemini/settings.json
    gemini
}
catch {
    Write-Error "Ошибка при запуске Gemini CLI: $_"
}

Write-Host "Gemini CLI завершил работу." -ForegroundColor Green