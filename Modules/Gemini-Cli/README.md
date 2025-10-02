# Руководство по Gemini CLI

лончер находится в C:\PowerShell\bin

**Gemini CLI** — инструмент для запуска интерактивного и неинтерактивного взаимодействия с моделями Gemini.  
Документация описывает команды, опции, PowerShell-обертки и типовые сценарии использования.

---

## Содержание
1. [Введение](#введение)  
2. [Команды](#команды)  
3. [Опции](#опции)  
4. [PowerShell-обертки](#powershell-обертки)  
   - [Invoke-Gemini](#1-invoke-gemini)  
   - [New-GeminiSession](#2-new-geminisession)  
   - [Set-GeminiSystemPrompt](#3-set-geminisystemprompt)  
5. [Примеры использования](#примеры-использования)  
6. [Типовые сценарии](#типовые-сценарии-использования)  
7. [Полезные советы](#полезные-советы)  

---

## Введение
Gemini CLI запускает интерактивный CLI.  
Для неинтерактивного режима используйте флаг `-p/--prompt`.  

```powershell
gemini [опции] [команда]
````

---

## Команды

* **gemini** — Запуск Gemini CLI *(по умолчанию)*
* **gemini mcp** — Управление MCP серверами

---

## Опции

* `-m, --model` — Модель *(string)*
* `-p, --prompt` — Промпт для CLI *(string)*
* `-i, --prompt-interactive` — Выполнить промпт и продолжить в интерактивном режиме *(string)*
* `-s, --sandbox` — Запуск в песочнице? *(boolean)*
* `--sandbox-image` — URI образа песочницы *(string)*
* `-d, --debug` — Включить режим отладки *(boolean, по умолчанию: false)*
* `-a, --all-files` — Включить все файлы в контекст *(boolean, по умолчанию: false)*
* `--all_files` *(устарело)* — Используйте `--all-files` *(boolean)*
* `--show-memory-usage` — Показать использование памяти *(boolean, по умолчанию: false)*
* `--show_memory_usage` *(устарело)* — Используйте `--show-memory-usage` *(boolean)*
* `-y, --yolo` — Автоматическое подтверждение всех действий *(boolean, по умолчанию: false)*
* `--approval-mode` — Режим подтверждения: `default`, `auto_edit`, `yolo` *(string)*
* `--telemetry` — Включить телеметрию *(boolean)*
* `--telemetry-target` — Цель телеметрии: `local` или `gcp` *(string)*
* `--telemetry-otlp-endpoint` — OTLP endpoint для телеметрии *(string)*
* `--telemetry-log-prompts` — Логировать пользовательские промпты *(boolean)*
* `--telemetry-outfile` — Перенаправить вывод телеметрии в файл *(string)*
* `-c, --checkpointing` — Включает контрольные точки файлов *(boolean, по умолчанию: false)*
* `--experimental-acp` — Запуск агента в ACP-режиме *(boolean)*
* `--allowed-mcp-server-names` — Разрешённые имена MCP серверов *(array)*
* `-e, --extensions` — Список расширений *(array)*
* `-l, --list-extensions` — Показать список расширений и выйти *(boolean)*
* `--proxy` — Прокси для клиента *(string)*
* `--include-directories` — Дополнительные директории *(array)*
* `-v, --version` — Показать версию *(boolean)*
* `-h, --help` — Показать справку *(boolean)*

---

## PowerShell-обертки

### 1. Invoke-Gemini

Разовый запрос к Gemini CLI.

```powershell
Invoke-Gemini -Prompt "Explain quantum computing"
```

**Параметры**:

* `-Prompt <string>` — текст запроса
* `-Args <string[]>` — дополнительные аргументы CLI

---

### 2. New-GeminiSession

Интерактивная сессия CLI:

```powershell
New-GeminiSession
```

---

### 3. Set-GeminiSystemPrompt

Системный промпт через файл `GEMINI.md`:

```powershell
Set-GeminiSystemPrompt -File "C:\configs\GEMINI.md"
```

Устанавливает переменную окружения `GEMINI_SYSTEM_MD`.

---

## Примеры использования

```powershell
# CLI интерактивно
gemini

# Неинтерактивно с промптом
gemini -p "Объясни квантовые вычисления"

# С моделью и песочницей
gemini -m "gemini-pro" -s -p "Сымитируй работу сервера"

# Через PowerShell-обертку
Invoke-Gemini -Prompt "Сделай резюме текста" -Args "--json" | ConvertFrom-Json | Format-Table
```

---

## Типовые сценарии использования

### 🔹 Генерация кода

```powershell
gemini -p "Напиши Python функцию, считающую факториал"
```

### 🔹 Редактирование файлов с checkpointing

```powershell
gemini -c -p "Добавь логирование в Python код"
```

### 🔹 Управление MCP

```powershell
gemini mcp --list
gemini mcp --start server1
```

### 🔹 Расширения

```powershell
gemini -l                     # список доступных
gemini -e "ext1" -e "ext2" -p "Используй только эти расширения"
```

### 🔹 Автоматизация через PowerShell

```powershell
Invoke-Gemini -Prompt "Переведи текст на немецкий" -Args "--json" |
    ConvertFrom-Json | Format-Table
```

### 🔹 Системный контекст

```powershell
Set-GeminiSystemPrompt -File "C:\configs\GEMINI.md"
New-GeminiSession
```

### 🔹 YOLO-режим

```powershell
gemini -y -p "Измени код и пересобери проект"
```

---

## Полезные советы

* `--debug` — для отладки CLI
* `--all-files` — если нужен полный контекст проекта
* Используйте PowerShell-обертки для скриптов и CI/CD
* Для длительной работы создавайте интерактивные сессии


