# 💾 Стратегии резервного копирования Ollama Stack

В этом документе описаны встроенные механизмы бэкапа, автоматизация через Планировщик задач Windows, процедуры восстановления и рекомендации по управлению дисковым пространством.

> ⚠️ **Дисклеймер:** Модели нейросетей занимают от 2 до 20+ ГБ каждая. Регулярное копирование папки `.ollama` требует значительного объёма диска. Настройте ротацию и внешний носитель заранее.

---

## 📁 Что включается в бэкап

Скрипт `backup.ps1` копирует только **пользовательские данные и конфигурацию**, игнорируя системные образы Docker/WSL:

| Компонент | Путь | Объём | Назначение |
|-----------|------|-------|------------|
| **Модели Ollama** | `%USERPROFILE%\.ollama\` | 2–50+ ГБ | Бинарные файлы моделей, кэш, манифесты |
| **Конфиг Ollama** | `%USERPROFILE%\.ollama\config.json` | ~1 КБ | Настройки GPU, потоков, контекста |
| **Данные WebUI** | `./webui-data/` | 50 МБ – 5 ГБ | SQLite (чаты, пользователи), RAG-документы, векторная БД |
| **Инфраструктура** | `docker-compose.yml` | ~2 КБ | Версия образов, порты, переменные окружения |

🚫 **Не бэкапится:**
- Диск WSL2 (`ext4.vhdx`)
- Образы Docker Desktop
- Временные файлы и кэш браузера
- ОС Windows и драйверы

---

## ⚙️ Как работает `backup.ps1`

```powershell
.\backup.ps1 -BackupRoot "D:\ollama-backups" -RetentionDays 14
```

### Алгоритм работы:
1. Создаёт папку с меткой времени: `backup\YYYY-MM-DD_HHmmss\`
2. Копирует данные через `robocopy` с оптимизациями:
   - `/MT:8` — многопоточное копирование (ускоряет передачу крупных моделей)
   - `/R:1 /W:1` — одна попытка при ошибке, пауза 1 сек (не блокирует скрипт)
   - `/NFL /NDL /NJH /NJS` — тихий режим (без списков файлов)
3. Подсчитывает итоговый размер и длительность операции
4. Удаляет папки старше `$RetentionDays` дней

📌 **Выходные коды `robocopy`:**
- `0–7` → Успех (копирование выполнено, возможны некритичные предупреждения)
- `8+` → Ошибка (скрипт прервётся с сообщением)

---

## 🔄 Автоматизация через Планировщик задач

Рекомендуется запускать бэкап ежедневно в период низкой нагрузки (например, 03:00).

### ️ Регистрация задачи (PowerShell от администратора)
```powershell
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PWD\backup.ps1`" -BackupRoot `"$PWD\backup`" -RetentionDays 7"

$trigger = New-ScheduledTaskTrigger -Daily -At 3am

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
  -RunLevel Highest -LogonType ServiceAccount

Register-ScheduledTask -TaskName "OllamaStack-DailyBackup" `
  -Action $action -Trigger $trigger -Principal $principal `
  -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false -DontStopIfGoingOnBatteries:$true)

Write-Host "✅ Задача 'OllamaStack-DailyBackup' создана" -ForegroundColor Green
```

### 📅 Проверка и управление
```powershell
# Просмотр статуса
Get-ScheduledTask -TaskName "OllamaStack-DailyBackup" | Select-Object TaskName, State, NextRunTime

# Ручной запуск задачи
Start-ScheduledTask -TaskName "OllamaStack-DailyBackup"

# Удаление задачи
Unregister-ScheduledTask -TaskName "OllamaStack-DailyBackup" -Confirm:$false
```

---

## 📥 Процедура восстановления

> ⚠️ **Важно:** Перед восстановлением остановите все службы, чтобы избежать повреждения SQLite и файловых блокировок.

### 1. Остановка компонентов
```powershell
# Остановка Open WebUI
docker compose down

# Остановка Ollama
Stop-Service -Name Ollama -Force
```

### 2. Копирование данных обратно
```powershell
# Укажите путь к нужному снапшоту
$restorePath = "backup\2024-05-15_030000"

# Восстановление моделей
robocopy "$restorePath\ollama" "$env:USERPROFILE\.ollama" /E /IS /IT /MT:8

# Восстановление WebUI
robocopy "$restorePath\webui" "$PWD\webui-data" /E /IS /IT /MT:8

# Восстановление конфигов
Copy-Item "$restorePath\docker-compose.yml" "$PWD\" -Force
Copy-Item "$restorePath\ollama-config.json" "$env:USERPROFILE\.ollama\config.json" -Force
```

### 3. Запуск и проверка
```powershell
Start-Service -Name Ollama
docker compose up -d
.\check-ai.ps1
```

✅ Если `check-ai.ps1` показывает `✅ OK` по всем пунктам — восстановление прошло успешно.

---

## 🗑️ Ротация и управление местом

### Автоматическая очистка
Скрипт удаляет бэкапы старше `$RetentionDays`. По умолчанию: `7 дней`.

### Ручная очистка старых бэкапов
```powershell
# Удалить все бэкапы старше 14 дней
Get-ChildItem "backup" -Directory | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-14)
} | Remove-Item -Recurse -Force
```

### Оптимизация для больших моделей
Если диск заполняется быстро, используйте **гибридную стратегию**:
```powershell
# Бэкап только WebUI и конфигов (ежедневно)
.\backup.ps1 -ExcludeOllamaModels

# Полный бэкап с моделями (раз в неделю или перед обновлением)
.\backup.ps1 -RetentionDays 30
```
*(Примечание: параметр `-ExcludeOllamaModels` требует доработки скрипта, но паттерн показывает логику разделения)*

---

## 🔒 Безопасность и рекомендации

| Практика | Описание |
|----------|----------|
|  **Внешний носитель** | Храните бэкапы на отдельном диске/NAS. При сбое SSD модели можно потерять безвозвратно. |
| 🔐 **Шифрование** | `backup.ps1` не шифрует данные. Для облака используйте `restic` или `7-Zip` с паролем. |
| 🧪 **Тестовое восстановление** | Раз в месяц проверяйте, что бэкап действительно разворачивается. Непроверенный бэкап = отсутствие бэкапа. |
| 📦 **Исключения** | Не бэкапьте `%USERPROFILE%\.ollama\tmp\` и кэш векторной БД, если используете RAG (пересоздаётся автоматически). |
| 🌐 **Offsite** | Для критичных чатов/документов настройте синхронизацию `webui-data` через `rclone` или `Syncthing`. |

---

## 📊 Сравнение стратегий

| Метод | Частота | Размер | Надёжность | Назначение |
|-------|---------|--------|------------|------------|
| `backup.ps1` (robocopy) | Ежедневно | Большой (полный) | ⭐⭐⭐⭐ | Быстрое локальное восстановление |
| Архивация (7-Zip) | Еженедельно | Средний (сжатие) | ⭐⭐⭐ | Перенос на внешний диск/облако |
| `restic` / `duplicati` | 2–3 раза/нед | Инкрементальный | ⭐⭐⭐⭐⭐ | Шифрование + дедупликация + версионирование |
| Снапшот `.vhdx` (WSL/Docker) | Перед обновлениями | Очень большой | ⭐⭐⭐ | Полное состояние виртуальных машин |

---