Тогда вот полный **`.md`** с переводом и примерами использования `Invoke-Gemini`, `New-GeminiSession` и `Set-GeminiSystemPrompt`:

````markdown
# Gemini CLI — Запуск интерактивного CLI

Использование:  
```powershell
gemini [опции] [команда]
````

Gemini CLI запускает интерактивный интерфейс.
Для неинтерактивного режима используйте `-p/--prompt`.

---

## Команды

* **gemini** — Запуск Gemini CLI *(по умолчанию)*
* **gemini mcp** — Управление MCP серверами

---

## Опции

* `-m, --model`
  Модель
  *(string)*

* `-p, --prompt`
  Промпт. Добавляется к входным данным из stdin (если они есть).
  *(string)*

* `-i, --prompt-interactive`
  Выполнить указанный промпт и продолжить работу в интерактивном режиме.
  *(string)*

* `-s, --sandbox`
  Запуск в песочнице?
  *(boolean)*

* `--sandbox-image`
  URI образа песочницы.
  *(string)*

* `-d, --debug`
  Запуск в режиме отладки.
  *(boolean, по умолчанию: false)*

* `-a, --all-files`
  Включить **ВСЕ** файлы в контекст.
  *(boolean, по умолчанию: false)*

* `--all_files` *(устарело)*
  Включить **ВСЕ** файлы в контекст.
  ⚠️ Используйте `--all-files`.
  *(boolean, по умолчанию: false)*

* `--show-memory-usage`
  Показать использование памяти в статус-баре.
  *(boolean, по умолчанию: false)*

* `--show_memory_usage` *(устарело)*
  Показать использование памяти в статус-баре.
  ⚠️ Используйте `--show-memory-usage`.
  *(boolean, по умолчанию: false)*

* `-y, --yolo`
  Автоматически принимать все действия (YOLO-режим).
  См. [видео](https://www.youtube.com/watch?v=xvFZjo5PgG0).
  *(boolean, по умолчанию: false)*

* `--approval-mode`
  Режим подтверждения:

  * `default` — спрашивать подтверждение
  * `auto_edit` — автоматически подтверждать действия инструментов редактирования
  * `yolo` — автоматически подтверждать всё
    *(string, варианты: "default", "auto\_edit", "yolo")*

* `--telemetry`
  Включить телеметрию?
  *(boolean)*

* `--telemetry-target`
  Установить цель телеметрии (`local` или `gcp`).
  Переопределяет настройки.
  *(string, варианты: "local", "gcp")*

* `--telemetry-otlp-endpoint`
  Задать OTLP endpoint для телеметрии.
  *(string)*

* `--telemetry-log-prompts`
  Включить/выключить логирование пользовательских промптов для телеметрии.
  *(boolean)*

* `--telemetry-outfile`
  Перенаправить весь вывод телеметрии в файл.
  *(string)*

* `-c, --checkpointing`
  Включает контрольные точки редактирования файлов.
  *(boolean, по умолчанию: false)*

* `--experimental-acp`
  Запуск агента в ACP-режиме.
  *(boolean)*

* `--allowed-mcp-server-names`
  Разрешённые имена MCP серверов.
  *(array)*

* `-e, --extensions`
  Список расширений для использования.
  Если не указано — загружаются все.
  *(array)*

* `-l, --list-extensions`
  Показать список доступных расширений и выйти.
  *(boolean)*

* `--proxy`
  Прокси для gemini-клиента (формат `schema://user:password@host:port`).
  *(string)*

* `--include-directories`
  Дополнительные директории для включения в рабочую область.
  *(array)*

* `-v, --version`
  Показать версию.
  *(boolean)*

* `-h, --help`
  Показать справку.
  *(boolean)*

---

## PowerShell-обертки

### 1. Invoke-Gemini

Выполняет разовый запрос к Gemini CLI.

```powershell
Invoke-Gemini -Prompt "Explain quantum computing"
```

**Параметры**:

* `-Prompt <string>` — обязательный промпт
* `-Args <string[]>` — дополнительные параметры CLI (например, `--json`)

---

### 2. New-GeminiSession

Запускает новую интерактивную сессию Gemini CLI.

```powershell
New-GeminiSession
```

---

### 3. Set-GeminiSystemPrompt

Задает системный промпт для Gemini CLI через файл `GEMINI.md`.

```powershell
Set-GeminiSystemPrompt -File "C:\configs\GEMINI.md"
```

**Переменная окружения:**
После выполнения будет установлена `GEMINI_SYSTEM_MD`.

---

## Примеры использования

```powershell
# Запуск CLI в интерактивном режиме
gemini

# Выполнение промпта напрямую
gemini -p "Объясни квантовые вычисления"

# Запуск с моделью и режимом песочницы
gemini -m "gemini-pro" -s -p "Сымитируй работу сервера"

# Использование PowerShell обертки
Invoke-Gemini -Prompt "Сделай резюме текста" -Args "--json"
```

```

Хочешь, я ещё добавлю раздел с **типовыми сценариями** (например: генерация кода, работа с MCP, настройка расширений), чтобы `.md` был как готовое руководство?
```
