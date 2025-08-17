# =================================================================================
# Clear-TempFiles.ps1 — Скрипт для безопасной очистки временных файлов
# Windows PowerShell >= 5.1.
# Требует запуска от имени администратора для полного доступа ко всем папкам.
# Автор: hypo69 (с помощью AI ассистента)
# Дата создания: 12/06/2025
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

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
.SYNOPSIS
    Очищает временные файлы и папки из стандартных расположений Windows.

.DESCRIPTION
    Скрипт рекурсивно удаляет файлы старше указанного количества дней из системных
    и пользовательских временных папок. Также опционально может очищать корзину
    и кэш загрузок Windows Update.

.PARAMETER DaysOld
    Удалять файлы старше указанного количества дней. По умолчанию: 7.

.PARAMETER WhatIf
    Показывает, какие файлы были бы удалены, но не выполняет удаление.

.PARAMETER IncludeRecycleBin
    Если указан, дополнительно очищает корзину.

.PARAMETER IncludeSoftwareDistribution
    Если указан, дополнительно очищает кэш загрузок Windows Update.
    (Использовать с осторожностью, если есть незавершенные обновления).

.EXAMPLE
    .\Clear-TempFiles.ps1 -WhatIf -Verbose
    Показывает, какие файлы старше 7 дней будут удалены, без фактического удаления.

.EXAMPLE
    .\Clear-TempFiles.ps1 -DaysOld 30 -Verbose
    Удаляет файлы старше 30 дней из временных папок.

.EXAMPLE
    .\Clear-TempFiles.ps1 -IncludeRecycleBin -IncludeSoftwareDistribution
    Выполняет полную очистку, включая корзину и кэш обновлений.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [int]$DaysOld = 7,
    [switch]$IncludeRecycleBin,
    [switch]$IncludeSoftwareDistribution
)

#----------------------------------------------------
#               ОСНОВНОЙ БЛОК СКРИПТА
#----------------------------------------------------

$totalSizeFreed = 0
$cutoffDate = (Get-Date).AddDays(-$DaysOld)

# --- 1. Определение списка путей для очистки ---
$cleanupPaths = @(
    $env:TEMP,
    "$env:windir\Temp"
)

if ($IncludeSoftwareDistribution) {
    $updateCachePath = "$env:windir\SoftwareDistribution\Download"
    $cleanupPaths += $updateCachePath
}

Write-Host "--- Начало очистки временных файлов старше $cutoffDate ---" -ForegroundColor Yellow

# --- 2. Перебор и очистка каждой директории ---
foreach ($path in $cleanupPaths) {
    if (-not (Test-Path -Path $path)) {
        Write-Warning "Путь не найден, пропуск: $path"
        continue
    }

    Write-Host "`nПроверка папки: $path" -ForegroundColor Cyan

    # Находим все файлы для удаления
    $filesToDelete = Get-ChildItem -Path $path -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoffDate }

    if ($filesToDelete) {
        # Считаем общий размер удаляемых файлов
        $sizeInPath = ($filesToDelete | Measure-Object -Property Length -Sum).Sum
        $totalSizeFreed += $sizeInPath
        $friendlySize = "{0:N2} MB" -f ($sizeInPath / 1MB)

        Write-Host "Найдено $($filesToDelete.Count) файлов для удаления (общий размер: $friendlySize)."

        if ($PSCmdlet.ShouldProcess($path, "Очистка файлов старше $($DaysOld) дней")) {
            $filesToDelete | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue -Verbose
        }
    }
    else {
        Write-Host "Файлы для удаления не найдены." -ForegroundColor Green
    }
    
    # --- 3. Удаление пустых подпапок после очистки ---
    Write-Verbose "Поиск и удаление пустых подпапок в '$path'..."
    $subfolders = Get-ChildItem -Path $path -Recurse -Force -Directory -ErrorAction SilentlyContinue
    # Сортируем по длине пути в обратном порядке, чтобы сначала удалять самые вложенные папки
    $subfolders | Sort-Object -Property @{E = { $_.FullName.Length } } -Descending | ForEach-Object {
        # Если в папке нет дочерних элементов
        if (-not (Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue)) {
            if ($PSCmdlet.ShouldProcess($_.FullName, "Удаление пустой папки")) {
                Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction SilentlyContinue -Verbose
            }
        }
    }
}

# --- 4. Опциональная очистка корзины ---
if ($IncludeRecycleBin) {
    Write-Host "`nОчистка корзины..." -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Корзина", "Полная очистка")) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "Корзина успешно очищена." -ForegroundColor Green
    }
}

# --- 5. Итоговый отчет ---
$friendlyTotalSize = if ($totalSizeFreed -gt 1GB) {
    "{0:N2} GB" -f ($totalSizeFreed / 1GB)
}
elseif ($totalSizeFreed -gt 1MB) {
    "{0:N2} MB" -f ($totalSizeFreed / 1MB)
}
else {
    "{0:N2} KB" -f ($totalSizeFreed / 1KB)
}

Write-Host "`n--- Очистка завершена ---" -ForegroundColor Yellow
Write-Host "Всего освобождено места: $friendlyTotalSize" -ForegroundColor Green