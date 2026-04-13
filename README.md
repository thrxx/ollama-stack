# 🤖 Ollama Stack — Локальный ИИ-ассистент

> Полностью локальный ИИ-ассистент с приватностью 100% — без отправки данных в облако

[![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Docker](https://img.shields.io/badge/Docker-Desktop-2496ED.svg)](https://www.docker.com/products/docker-desktop)
[![Ollama](https://img.shields.io/badge/Ollama-latest-FF6F00.svg)](https://ollama.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 📋 Оглавление

- [Возможности](#-возможности)
- [Системные требования](#-системные-требования)
- [Быстрый старт](#-быстрый-старт)
- [Установка](#-установка)
- [Использование](#-использование)
- [Конфигурация](#-конфигурация)
- [Скрипты](#-скрипты)
- [Рекомендуемые модели](#-рекомендуемые-модели)
- [Мониторинг и отладка](#-мониторинг-и-отладка)
- [Бэкап](#-бэкап)
- [Частые проблемы](#-частые-проблемы)
- [Структура проекта](#-структура-проекта)
- [Лицензия](#-лицензия)

---

## ✨ Возможности

- 🔒 **100% приватность** — все данные остаются на вашем компьютере
- 🚀 **Высокая производительность** — оптимизация для NVIDIA GPU (RTX 3070 и др.)
- 🌐 **Веб-интерфейс** — удобный чат через Open WebUI
- 📁 **RAG** — работа с документами (PDF, DOCX, TXT, MD)
- 🇷🇺 **Мультиязычность** — полная поддержка русского языка
- 🔌 **API** — интеграция с внешними сервисами
- 📊 **Мониторинг** — отслеживание GPU, RAM, VRAM в реальном времени

---

## 💻 Системные требования

| Компонент | Минимальные | Рекомендуемые |
|-----------|-------------|---------------|
| **ОС** | Windows 11 Pro 22H2 | Windows 11 Pro 23H2+ |
| **CPU** | Intel i7-10700 / AMD Ryzen 7 3700X | Intel i7-12700K / AMD Ryzen 7 5800X |
| **RAM** | 16 ГБ | 32 ГБ |
| **GPU** | NVIDIA GTX 1660 (6GB VRAM) | NVIDIA RTX 3070 (8GB VRAM) |
| **Диск** | 100 ГБ SSD | 500 ГБ NVMe SSD |
| **Сеть** | Интернет (для загрузки) | — |

> 💡 **Проверка виртуализации**: `systeminfo | Select-String "Virtualization"`

---

## 🚀 Быстрый старт

```powershell
# 1. Клонируйте репозиторий
git clone https://github.com/your-username/ollama-stack.git
cd ollama-stack

# 2. Запустите полную установку (от администратора)
.\install-all.ps1

# 3. Перезагрузите компьютер

# 4. Запустите ассистента
.\start-assistant.ps1
```

✅ **Готово!** Откройте браузер: http://localhost:3000

---

## 📥 Установка

```powershell
# Запустите PowerShell ОТ ИМЕНИ АДМИНИСТРАТОРА
.\install-all.ps1
```

Скрипт автоматически:
- ✅ Проверит системные требования
- ✅ Установит WSL2
- ✅ Установит Ollama
- ✅ Установит Docker Desktop
- ✅ Создаст структуру проекта
- ✅ Настроит конфигурацию

---

## 🎯 Использование

### Запуск ассистента

```powershell
# Из папки проекта
.\start-assistant.ps1
```

### Диагностика системы

```powershell
# Проверка всех компонентов
.\check-ai.ps1

# Подробная диагностика
.\check-ai.ps1 -Detailed
```

### Управление моделями

```powershell
# Загрузка модели
ollama pull qwen2.5:7b-instruct-q4_k_m

# Список моделей
ollama list

# Удаление модели
ollama rm <имя_модели>

# Обновление модели
ollama pull qwen2.5:7b-instruct-q4_k_m --force
```

---

## ⚙️ Конфигурация

### Ollama (config.json)

Расположение: `%USERPROFILE%\.ollama\config.json`

```json
{
  "num_gpu": 99,
  "num_thread": 12,
  "main_gpu": 0,
  "low_vram": false,
  "num_batch": 512
}
```

| Параметр | Значение | Назначение |
|----------|----------|------------|
| `num_gpu` | 99 | Загрузить все слои модели в VRAM |
| `num_thread` | 12 | Использовать производительные ядра CPU |
| `main_gpu` | 0 | Основная видеокарта |
| `low_vram` | false | Для 8 ГБ VRAM и более |
| `num_batch` | 512 | Размер пакета для баланса скорости |

> 📝 Пример файла: [config.json.example](config.json.example)

### Docker Compose

Основной файл: [docker-compose.yml](docker-compose.yml)

Ключевые переменные окружения:
- `OLLAMA_BASE_URL` — адрес Ollama API
- `DISABLE_ANALYTICS` — отключение телеметрии
- `ENABLE_RAG` — работа с документами
- `DEFAULT_CONTEXT_LENGTH` — длина контекста модели

---

## 📜 Скрипты

| Скрипт | Описание |
|--------|----------|
| [`install-all.ps1`](install-all.ps1) | Полная установка всех компонентов |
| [`start-assistant.ps1`](start-assistant.ps1) | Запуск ассистента и открытие WebUI |
| [`check-ai.ps1`](check-ai.ps1) | Диагностика состояния компонентов |
| [`backup.ps1`](backup.ps1) | Автоматический бэкап данных |

> ⚠️ **Важно**: `install-all.ps1` требует запуска **от имени администратора**

---

## 🧠 Рекомендуемые модели

| Модель | Размер | Скорость* | Русский | Назначение |
|--------|--------|-----------|---------|------------|
| **qwen2.5:7b-instruct-q4_k_m** | ~4.2 ГБ | 🔥 35-45 т/с | ⭐⭐⭐⭐⭐ | Универсальный ассистент |
| **llama3.1:8b-instruct-q4_k_m** | ~4.9 ГБ | 🔥 30-40 т/с | ⭐⭐⭐⭐ | Логика, код, английский |
| **qwen2.5:3b-instruct-q4_k_m** | ~2.1 ГБ | 🚀 60-90 т/с | ⭐⭐⭐⭐ | Быстрые ответы |
| **qwen2.5:14b-instruct-q4_k_m** | ~9.1 ГБ | ⚡ 12-18 т/с | ⭐⭐⭐⭐⭐ | Сложный анализ |
| **saiga:7b-lora-q4_k_m** | ~4.5 ГБ | 🔥 30-40 т/с | ⭐⭐⭐⭐⭐⭐ | Только русский |

> *т/с = токенов в секунду (RTX 3070, q4_k_m)

### Почему `q4_k_m`?

Оптимальное квантование: потеря качества <1%, экономия памяти 40-50%, скорость выше в 2 раза по сравнению с `fp16`.

---

## 📊 Мониторинг и отладка

### Реальный мониторинг

```powershell
# GPU (обновление каждую секунду)
nvidia-smi -l 1

# Статус моделей
ollama ps

# Логи Ollama
Get-Content "$env:LOCALAPPDATA\Ollama\logs\server.log" -Tail 50

# Логи Open WebUI
docker compose logs -f open-webui
```

### Ожидаемая производительность (RTX 3070)

| Модель | Токены/сек | Память |
|--------|------------|--------|
| 3B (q4_k_m) | 60-90 | ~2.5 ГБ |
| 7B (q4_k_m) | 30-45 | ~4.5 ГБ |
| 8B (q4_k_m) | 28-40 | ~5.2 ГБ |
| 14B (q4_k_m) | 12-18 | ~9.5 ГБ* |

> *Для 14B часть слоёв будет в системной RAM

---

## 💾 Бэкап

### Ручной бэкап

```powershell
.\backup.ps1
```

### Автоматический бэкап (Планировщик задач)

```powershell
# Создание задачи на ежедневный бэкап в 03:00
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PWD\backup.ps1`""
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "OllamaStack-Backup" -Action $action -Trigger $trigger -Principal $principal
```

### Что бэкапится?

- 📦 Модели Ollama (`%USERPROFILE%\.ollama`)
- 💬 Данные Open WebUI (чаты, пользователи, настройки)
- ⚙️ Файлы конфигурации

---

## 🔧 Частые проблемы

| Симптом | Причина | Решение |
|---------|---------|---------|
| 🔴 `host.docker.internal` не резолвится | Docker не в режиме WSL2 | Docker Desktop → Settings → WSL Integration → ✅ Enable |
| 🔴 Модель грузится в RAM, не в GPU | Неверный config.json | Проверьте `num_gpu: 99`, перезапустите Ollama |
| 🔴 Open WebUI: "Connection failed" | Брандмауэр блокирует порт | Разрешите порт 11434 в Защитнике Windows |
| 🔴 "CUDA out of memory" | Модель не влезает в VRAM | Используйте `q4_k_m`, уменьшите контекст до 4096 |
| 🔴 Медленная генерация (<10 т/с) | Модель в RAM | Проверьте `ollama ps`, загрузите `q4_k_m` версию |
| 🔴 Docker не видит WSL2 | Устаревшая версия | Обновите Docker Desktop и WSL: `wsl --update` |

### Экстренные команды

```powershell
# Перезапуск всего стека
Restart-Service -Name "Ollama" -Force
docker compose restart

# Полная переустановка Open WebUI (данные сохранятся)
docker compose down
docker compose up -d
```

---

## 📁 Структура проекта

```
ollama-stack/
├── 📄 README.md                  # Документация (этот файл)
├── 📄 LICENSE                    # Лицензия MIT
├── 📄 docker-compose.yml         # Конфигурация Open WebUI
├── 📄 config.json.example        # Пример config для Ollama
│
├── 🔧 install-all.ps1            # Скрипт полной установки
├── 🚀 start-assistant.ps1        # Скрипт запуска ассистента
├── 🔍 check-ai.ps1               # Скрипт диагностики
├── 💾 backup.ps1                 # Скрипт бэкапа
│
└── 📁 webui-data/                # Данные Open WebUI (создаётся автоматически)
    └── ...                       # Чаты, пользователи, документы
```

---

## 🔐 Безопасность

- 🔒 Все данные хранятся **локально** на вашем компьютере
- 🚫 Нет телеметрии или отправки данных в облако
- 🔐 При открытии в сеть рекомендуется:
  - Настроить аутентификацию в Open WebUI
  - Использовать HTTPS через обратный прокси (Nginx/Caddy)

---

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте ветку (`git checkout -b feature/amazing-feature`)
3. Commit изменений (`git commit -m 'Add amazing feature'`)
4. Push в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

---

## 📝 Лицензия

Этот проект распространяется под лицензией MIT. Подробности в файле [LICENSE](LICENSE).

---
