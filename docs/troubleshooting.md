# 🚦 Устранение неполадок (Troubleshooting)

В этом документе собраны типовые проблемы, их причины и способы решения. Рекомендуется всегда начинать диагностику с встроенного скрипта проверки.

---

## 🔍 Быстрая диагностика

Запустите из корня проекта:
```powershell
.\check-ai.ps1 -Detailed
```

**Коды завершения:**
| Код | Значение | Действие |
|-----|----------|----------|
| `0` | ✅ Всё работает | Можно продолжать работу |
| `1` | ⚠️ Частичные проблемы | Проверьте предупреждения (например, нет моделей или GPU не detected) |
| `2` | 🚨 Критические ошибки | Остановите стек, проверьте логи, восстановите конфигурацию |

---

## 📋 Типовые проблемы

### 🛠️ Установка и подготовка

| Симптом | Причина | Решение |
|---------|---------|---------|
| `Запустите скрипт от имени администратора` | Отсутствуют elevated права | ПКМ по PowerShell → **Запуск от имени администратора** |
| `Виртуализация отключена` | VT-x/AMD-V выключен в BIOS/UEFI | Перезагрузитесь в BIOS → включить `Virtualization Technology` → `wsl --install` |
| `WSL2 installation is incomplete` | Устаревший компонент ядра Linux | `wsl --update` → `wsl --shutdown` → повторите установку |
| Ошибка загрузки `.exe` установщиков | Блокировка антивирусом / прокси / TLS 1.2 | Скачайте вручную: [Ollama](https://ollama.com/download/windows), [Docker](https://www.docker.com/products/docker-desktop). Отключите VPN/прокси на время установки |

### 🐳 Запуск служб и контейнеров

| Симптом | Причина | Решение |
|---------|---------|---------|
| Docker не отвечает, `docker info` падает | Docker Desktop не запущен или не в режиме WSL2 | Откройте Docker Desktop → дождитесь 🟢 → Settings → General → ✅ **Use WSL 2 based engine** |
| `host.docker.internal` не резолвится | Конфликт сетевых драйверов / устаревшая версия Docker | `wsl --shutdown` → перезапуск Docker Desktop. Если не помогло: Settings → Resources → WSL Integration → ✅ Enable |
| Port `3000` или `11434` уже используется | Конфликт с IIS, Node, другим Docker-контейнером | `netstat -ano \| findstr :3000` → найдите PID → `taskkill /PID <PID> /F` или измените порт в `docker-compose.yml` |
| Контейнер `open-webui` сразу останавливается | Ошибка конфигурации / нехватка памяти / конфликт volumes | `docker compose logs open-webui` → ищите `ERROR` → проверьте `docker-compose.yml` и права на `./webui-data` |

###  Ollama и генерация

| Симптом | Причина | Решение |
|---------|---------|---------|
| `CUDA out of memory` | Модель не помещается в VRAM | Используйте квантование `q4_k_m`, уменьшите `DEFAULT_CONTEXT_LENGTH` до `4096`, закройте тяжёлые приложения (игры, рендер) |
| Генерация идёт на CPU (`vmmem` грузит процессор) | `num_gpu` ≠ 99 или драйверы NVIDIA устарели | Проверьте `%USERPROFILE%\.ollama\config.json` → `num_gpu = 99`. Обновите драйверы через GeForce Experience |
| Первый ответ задерживается на 10-30 сек | Холодный старт: модель загружается с диска в VRAM | Нормальное поведение. После первого запроса модель остаётся в памяти ~5 мин |
| `ollama list` не показывает модели | Модели скачаны под другим пользователем или повреждён кэш | Проверьте путь `%USERPROFILE%\.ollama\models`. При подозрении на повреждение: `ollama rm <model>` → `ollama pull <model>` |

### 🌐 Сеть и доступ из LAN

| Симптом | Причина | Решение |
|---------|---------|---------|
| WebUI недоступен по IP в локальной сети | Брандмауэр Windows блокирует входящие | `New-NetFirewallRule -DisplayName "WebUI-LAN" -Direction Inbound -Protocol TCP -LocalPort 3000 -Profile Private -Action Allow` |
| Ollama API недоступен извне | Служба слушает только `127.0.0.1` | `[Environment]::SetEnvironmentVariable("OLLAMA_HOST","0.0.0.0","User")` → `Restart-Service Ollama` |
| Медленный отклик из LAN | DNS-резолвинг hostname или Wi-Fi задержки | Используйте IP-адрес ПК вместо `hostname.local`. Проверьте кабельное подключение |

### 💾 Бэкап и восстановление

| Симптом | Причина | Решение |
|---------|---------|---------|
| `robocopy` возвращает код `8` и выше | Нет места, файл заблокирован, антивирус | Освободите >20 ГБ, остановите Docker/Ollama перед бэкапом, добавьте папку в исключения Защитника |
| Не удаляются старые бэкапы | Несоответствие формата имени папки `yyyy-MM-dd_HHmmss` | Проверьте, что папки созданы скриптом. Для ручного удаления: `Get-ChildItem backup -Directory \| Remove-Item -Recurse -Force` |
| После восстановления WebUI падает с `Database locked` | SQLite файл занят процессом или скопирован "на горячую" | Всегда останавливайте контейнер перед копированием: `docker compose down` → восстановите → `docker compose up -d` |

---

## 📂 Расположение логов

| Компонент | Путь / Команда | Что искать |
|-----------|----------------|------------|
| **Ollama Service** | `%LOCALAPPDATA%\Ollama\logs\server.log` | `error`, `cuda`, `oom`, `panic` |
| **Open WebUI** | `docker compose logs -f open-webui` | `Connection refused`, `SQLITE_BUSY`, `uvicorn` ошибки |
| **Docker Desktop** | `%LOCALAPPDATA%\Docker\log.txt` | Проблемы с WSL2 integration, volumes, network |
| **Windows Service** | `Get-EventLog -LogName Application -Source Ollama -Newest 20` | Падения службы, права доступа |
| **Скрипты** | Консоль PowerShell | Вывод `check-ai.ps1 -Detailed`, коды выхода `robocopy` |

---

## 🛠️ Аварийные команды

Используйте при нестабильной работе стека. **Данные не теряются.**

```powershell
# 1. Полная остановка без удаления данных
docker compose down
Stop-Service Ollama -Force

# 2. Очистка зависших контейнеров/сетей
docker system prune -f
wsl --shutdown

# 3. Перезапуск с нуля
Start-Service Ollama
Start-Sleep -Seconds 3
docker compose up -d

# 4. Принудительное обновление образов WebUI
docker compose pull
docker compose up -d --force-recreate
```

> ⚠️ **Внимание:** `docker system prune` удаляет остановленные контейнеры и неиспользуемые образы, но **не трогает** volumes (`webui-data`) и модели Ollama.

---