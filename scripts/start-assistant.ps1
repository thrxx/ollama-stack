<#
.SYNOPSIS
    Запуск локального ИИ-ассистента (Ollama + Open WebUI)
.DESCRIPTION
    Проверяет все службы, запускает Open WebUI и открывает интерфейс в браузере
.NOTES
    Запускать из папки проекта ollama-stack
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Port = "3000"
)

$ErrorActionPreference = "Stop"

# ═══════════════════════════════════════════════════════
# Цветной вывод
# ═══════════════════════════════════════════════════════
function Write-Step([string]$Message, [ConsoleColor]$Color = "Cyan") {
    Write-Host "`n▶ $Message" -ForegroundColor $Color
}

function Write-OK([string]$Message = "Готово") {
    Write-Host "  ✅ $Message" -ForegroundColor Green
}

function Write-Fail([string]$Message) {
    Write-Host "  ❌ $Message" -ForegroundColor Red
}

function Write-Warn([string]$Message) {
    Write-Host "  ⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info([string]$Message) {
    Write-Host "  ℹ️  $Message" -ForegroundColor DarkGray
}

# ═══════════════════════════════════════════════════════
# 0. Приветствие
# ═══════════════════════════════════════════════════════
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       🤖 ЗАПУСК ЛОКАЛЬНОГО ИИ-АССИСТЕНТА           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════
# 1. Проверка Ollama
# ═══════════════════════════════════════════════════════
Write-Step "Проверка Ollama..."

if (Get-Service -Name "Ollama" -ErrorAction SilentlyContinue) {
    $ollamaService = Get-Service -Name "Ollama"
    if ($ollamaService.Status -eq "Running") {
        Write-OK "Ollama: служба запущена"
    } else {
        Write-Warn "Ollama: служба остановлена, пытаемся запустить..."
        try {
            Start-Service -Name "Ollama"
            Write-OK "Ollama: служба запущена"
        } catch {
            Write-Fail "Ollama: не удалось запустить службу"
            Write-Warn "Запустите вручную: Start-Service -Name 'Ollama'"
            exit 1
        }
    }

    # Проверка API
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:11434" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-OK "Ollama API: доступен"
        }
    } catch {
        Write-Fail "Ollama API: не отвечает на порту 11434"
        Write-Warn "Проверьте: Restart-Service -Name 'Ollama' -Force"
        exit 1
    }
} else {
    Write-Fail "Ollama: служба не установлена"
    Write-Warn "Установите: .\install-all.ps1"
    Write-Warn "Или скачайте: https://ollama.com/download/windows"
    exit 1
}

# ═══════════════════════════════════════════════════════
# 2. Проверка Docker
# ═══════════════════════════════════════════════════════
Write-Step "Проверка Docker..."

try {
    docker info 2>$null | Out-Null
    Write-OK "Docker: работает"
} catch {
    Write-Fail "Docker: не работает"
    Write-Warn "Запустите Docker Desktop и дождитесь зелёного индикатора"
    Write-Warn "Проверьте: docker info"
    exit 1
}

# ═══════════════════════════════════════════════════════
# 3. Проверка docker-compose.yml
# ═══════════════════════════════════════════════════════
Write-Step "Проверка конфигурации..."

$composeFile = Join-Path $PWD "docker-compose.yml"
if (Test-Path $composeFile) {
    Write-OK "docker-compose.yml: найден"
} else {
    Write-Fail "docker-compose.yml: не найден в текущей папке"
    Write-Warn "Убедитесь, что вы запустили скрипт из папки ollama-stack"
    Write-Warn "Или запустите: .\install-all.ps1"
    exit 1
}

# ═══════════════════════════════════════════════════════
# 4. Запуск Open WebUI
# ═══════════════════════════════════════════════════════
Write-Step "Запуск Open WebUI..."

try {
    $containerStatus = docker compose ps --format json 2>$null
    if ($containerStatus -match '"State":"running"') {
        Write-OK "Open WebUI: уже запущен"
    } else {
        Write-Host "  🐳 Запуск контейнера..." -ForegroundColor DarkGray
        docker compose up -d 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-OK "Open WebUI: запущен"
        } else {
            Write-Fail "Open WebUI: ошибка запуска"
            Write-Warn "Попробуйте: docker compose up -d (вручную для логов)"
            exit 1
        }
    }
} catch {
    Write-Fail "Open WebUI: ошибка - $_"
    exit 1
}

# ═══════════════════════════════════════════════════════
# 5. Ожидание готовности
# ═══════════════════════════════════════════════════════
Write-Step "Ожидание готовности сервиса..."

$maxAttempts = 10
$attempt = 0
$ready = $false

while ($attempt -lt $maxAttempts -and -not $ready) {
    $attempt++
    Write-Host "  ⏳ Попытка $attempt/$maxAttempts..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 2

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            $ready = $true
        }
    } catch {
        # Сервис ещё не готов
    }
}

if ($ready) {
    Write-OK "Сервис готов на порту $Port"
} else {
    Write-Warn "Сервис может быть ещё не готов, попробуйте через несколько секунд"
}

# ═══════════════════════════════════════════════════════
# 6. Открытие браузера
# ═══════════════════════════════════════════════════════
Write-Step "Открытие веб-интерфейса..."

$webUrl = "http://localhost:$Port"
try {
    Start-Process $webUrl
    Write-OK "Браузер открыт: $webUrl"
} catch {
    Write-Warn "Не удалось открыть браузер, перейдите вручную: $webUrl"
}

# ═══════════════════════════════════════════════════════
# 7. Информация о моделях
# ═══════════════════════════════════════════════════════
Write-Step "Загруженные модели Ollama:"

try {
    $models = ollama list 2>$null
    if ($models) {
        Write-Host $models | ForEach-Object {
            Write-Host "     $_" -ForegroundColor White
        }
    } else {
        Write-Warn "Нет загруженных моделей"
        Write-Info "Рекомендуем: ollama pull qwen2.5:7b-instruct-q4_k_m"
    }
} catch {
    Write-Warn "Не удалось получить список моделей"
}

# ═══════════════════════════════════════════════════════
# 8. Итоговая информация
# ═══════════════════════════════════════════════════════
Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✅ АССИСТЕНТ ГОТОВ!                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📦 ИНТЕРФЕЙС:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "   🔗 $webUrl" -ForegroundColor White
Write-Host "   🔌 Ollama: http://host.docker.internal:11434" -ForegroundColor White
Write-Host "`n💡 СОВЕТЫ:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "   • Первая генерация: 10-30 сек (загрузка в VRAM)" -ForegroundColor White
Write-Host "   • Последующие ответы: мгновенно" -ForegroundColor White
Write-Host "   • Мониторинг GPU: nvidia-smi -l 1" -ForegroundColor White
Write-Host "   • Статус контейнера: docker compose ps" -ForegroundColor White
Write-Host "   • Логи: docker compose logs -f" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray
