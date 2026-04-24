# 🌐 Сетевая конфигурация Ollama Stack

В этом документе описана сетевая архитектура проекта, маршрутизация трафика между компонентами и настройка доступа из локальной сети.

---

## 📡 Топология по умолчанию

По умолчанию весь стек работает **изолированно на localhost**. Внешние соединения не требуются (кроме одноразовой загрузки моделей).

```
[Браузер] ──http://localhost:3000──▶ [Docker NAT] ──▶ [Контейнер Open WebUI]
                                                     │
                                                     └─http://host.docker.internal:11434─▶ [Служба Ollama (Windows)]
```

| Компонент | Адрес | Протокол | Назначение |
|-----------|-------|----------|------------|
| **Open WebUI** | `http://localhost:3000` | HTTP/REST + SSE | Веб-интерфейс чата |
| **Ollama API** | `http://localhost:11434` | HTTP/REST | Генерация токенов, управление моделями |
| **Docker Daemon** | `npipe:////./pipe/docker_engine` | Named Pipe | Управление контейнерами (Windows) |

---

## 🔗 Мост Docker ↔ Windows

Поскольку **Ollama работает нативно в Windows**, а **WebUI запущен в контейнере**, им необходим сетевой мост. Docker Desktop предоставляет встроенный DNS-резолвер:

### `host.docker.internal`
- Специальное доменное имя, которое **внутри контейнера** резолвится во внутренний IP хоста Windows.
- Позволяет контейнеру обращаться к службам Windows без проброса портов или ручной настройки IP.
- Используется в `docker-compose.yml`:
  ```yaml
  environment:
    - OLLAMA_BASE_URL=http://host.docker.internal:11434
  ```

⚠️ **Важно:** `host.docker.internal` работает **только** в Docker Desktop (WSL2/Hyper-V backend). В чистом Linux или Docker Engine без дополнительной настройки он недоступен.

---

## 🚪 Карта портов

Docker Compose автоматически управляет пробросом портов при запуске `docker compose up -d`.

| Хост (Windows) | Контейнер (WebUI) | Протокол | Статус | Примечание |
|----------------|-------------------|----------|--------|------------|
| `3000` | `8080` | TCP | ✅ Открыт | Веб-интерфейс |
| `11434` | — | TCP | 🔒 Localhost | Ollama API (только 127.0.0.1) |
| `2375` / `2376` | — | TCP | 🔒 Localhost | Docker API (для управления) |

💡 **Примечание:** Ollama по умолчанию привязан к `127.0.0.1`. Это безопасно и предотвращает случайный доступ из LAN к API генерации.

---

## 🌍 Доступ из локальной сети (LAN)

> ⚠️ **Дисклеймер:** Открытие сервисов в сеть требует понимания рисков. Ollama **не имеет встроенной аутентификации**. Используйте только в доверенных сетях или за reverse-proxy.

### 1. Доступ к WebUI из LAN
Docker Compose по умолчанию публикует порт `3000` на все интерфейсы (`0.0.0.0`). Доступ работает сразу, если разрешён брандмауэром.

**Как подключиться:**
```
http://<IP_ВАШЕГО_ПК>:3000
```
📌 *Совет:* Используйте `hostname.local` (mDNS/Bonjour) или назначьте статический IP в роутере, чтобы не зависеть от DHCP.

### 2. Доступ к Ollama API из LAN (опционально)
Если внешние сервисы (VS Code, скрипты, другие ПК) должны обращаться к API:

1. Откройте переменные среды Windows:
   ```powershell
   [Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0", "User")
   ```
2. Перезапустите службу:
   ```powershell
   Restart-Service -Name Ollama
   ```
3. API станет доступен по `http://<IP_ВАШЕГО_ПК>:11434`.

🔒 **Настоятельно рекомендуется** закрывать порт `11434` на роутере и не пробрасывать его в интернет.

### 3. Reverse Proxy (рекомендуемый путь для LAN)
Для безопасного доступа из сети используйте Nginx/Caddy/Traefik:
- Терминирует HTTPS (Let's Encrypt)
- Добавляет базовую аутентификацию
- Скрывает внутренние порты
- Пример конфига Nginx есть в `docs/examples/reverse-proxy/`

---

## 🛡️ Брандмауэр Windows

Docker Desktop автоматически создаёт правила для проброшенных портов. Однако Windows Defender может блокировать входящие соединения, особенно в профиле `Public`.

### Проверка текущего профиля сети
```powershell
Get-NetConnectionProfile | Select-Object Name, NetworkCategory
```
✅ Убедитесь, что ваша сеть имеет категорию `Private`.

### Ручное создание правила (если WebUI недоступен из LAN)
```powershell
# Разрешить порт 3000 только для частного профиля
New-NetFirewallRule -DisplayName "Ollama-WebUI-LAN" `
  -Direction Inbound -Protocol TCP -LocalPort 3000 `
  -Profile Private -Action Allow
```

### Для Ollama API (если открыт в LAN)
```powershell
New-NetFirewallRule -DisplayName "Ollama-API-LAN" `
  -Direction Inbound -Protocol TCP -LocalPort 11434 `
  -Profile Private -Action Allow
```

🚫 **Никогда** не используйте `-Profile Any` или `-Profile Public` для этих правил.

---

## 🚦 Устранение сетевых неполадок

| Симптом | Причина | Решение |
|---------|---------|---------|
| WebUI показывает `Connection failed` | Контейнер не резолвит `host.docker.internal` | В Docker Desktop: Settings → General → ✅ Use WSL 2 based engine. Перезапустите Docker. |
| Порт `3000` занят | Другое приложение (IIS, Node, another Docker) | `netstat -ano \| findstr :3000` → найдите PID → остановите или измените порт в `docker-compose.yml` |
| `host.docker.internal` не отвечает | Антивирус/фаервол блокирует Docker NAT | Добавьте `Docker Desktop.exe` и `vmmem` в исключения Защитника Windows |
| Медленный первый запрос из LAN | DNS-резолвинг или handshake | Используйте IP вместо hostname; убедитесь, что кабель/Wi-Fi стабильны |
| Ollama API недоступен после `OLLAMA_HOST=0.0.0.0` | Служба не перезапустилась или порт занят | `Get-Service Ollama \| Restart-Service`; проверьте `netstat -ano \| findstr :11434` |

### Диагностические команды
```powershell
# Проверка занятости портов
netstat -ano | Select-String ":3000|:11434"

# Тест доступности из контейнера (через Docker)
docker run --rm nicolaka/netshoot curl -s http://host.docker.internal:11434

# Проверка правил фаервола
Get-NetFirewallRule -DisplayName "*Ollama*" | Format-Table DisplayName, Enabled, Profile, Action
```

---

## 🔒 Рекомендации по безопасности

1. **Оставляйте Ollama на `127.0.0.1`**, если к API обращается только WebUI.
2. **Используйте аутентификацию WebUI** (настраивается при первом входе).
3. **Не пробрасывайте порты на роутере** без reverse-proxy и HTTPS.
4. **Обновляйте Docker Desktop и Ollama** регулярно (сетевые уязвимости закрываются в патчах).
5. **Мониторьте входящие соединения**:
   ```powershell
   Get-NetTCPConnection -LocalPort 3000,11434 | Select-Object LocalAddress, RemoteAddress, State
   ```

---