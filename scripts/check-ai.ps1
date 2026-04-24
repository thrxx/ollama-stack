<#
.SYNOPSIS
    Диагностика локального ИИ-ассистента
.DESCRIPTION
    Проверяет состояние всех компонентов: Ollama, Docker, Open WebUI, GPU
.NOTES
    Запускать из папки проекта ollama-stack
#>

[CmdletBinding()]
param(
    [switch]$Detailed
)

$ErrorActionPreference = "Continue"

# ═══════════════════════════════════════════════════════
# Цветной вывод
# ═══════════════════════════════════════════════════════
function Write-Pass([string]$Message) {
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Fail([string]$Message) {
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warn([string]$Message) {
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info([string]$Message) {
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Header([string]$Message) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "▶ $Message" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
}

# ═══════════════════════════════════════════════════════
# Счётчики
# ═══════════════════════════════════════════════════════
$okCount = 0
$failCount = 0
$warnCount = 0

# ═══════════════════════════════════════════════════════
# Приветствие
# ═══════════════════════════════════════════════════════
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🔍 ДИАГНОСТИКА ЛОКАЛЬНОГО ИИ-АССИСТЕНТА        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════
# 1. Проверка Ollama
# ═══════════════════════════════════════════════════════
Write-Header "1. Ollama (бэкенд)"

# Служба
if (Get-Service -Name "Ollama" -ErrorAction SilentlyContinue) {
    $ollamaService = Get-Service -Name "Ollama"
    if ($ollamaService.Status -eq "Running") {
        Write-Pass "Ollama: служба запущена ($($ollamaService.Status))"
        $okCount++
    } else {
        Write-Warn "Ollama: служба остановлена ($($ollamaService.Status))"
        $warnCount++
    }
} else {
    Write-Fail "Ollama: служба не установлена"
    $failCount++
}

# API
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:11434" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Pass "Ollama API: доступен (http://127.0.0.1:11434)"
        $okCount++

        # Версия
        try {
            $version = ollama --version 2>$null
            if ($version) {
                Write-Info "Версия: $version"
            }
        } catch {
            # Не критично
        }
    }
} catch {
    Write-Fail "Ollama API: не отвечает на порту 11434"
    $failCount++
}

# Загруженные модели
Write-Host "`n  📦 Загруженные модели:" -ForegroundColor DarkGray
try {
    $models = ollama list 2>$null
    if ($models -and $models -notmatch "^NAME") {
        $modelList = $models | Select-Object -Skip 1
        foreach ($model in $modelList) {
            Write-Host "     • $model" -ForegroundColor White
        }
        $okCount++
    } else {
        Write-Warn "Нет загруженных моделей (рекомендуем: ollama pull qwen2.5:7b-instruct-q4_k_m)"
        $warnCount++
    }
} catch {
    Write-Warn "Не удалось получить список моделей"
    $warnCount++
}

# ═══════════════════════════════════════════════════════
# 2. Проверка Docker
# ═══════════════════════════════════════════════════════
Write-Header "2. Docker"

try {
    $dockerInfo = docker info 2>$null
    if ($dockerInfo) {
        Write-Pass "Docker: работает"
        $okCount++

        if ($Detailed) {
            # Режим (WSL2/Hyper-V)
            $wslMode = $dockerInfo | Select-String "WSL"
            if ($wslMode) {
                Write-Info "Режим: WSL2"
            } else {
                Write-Warn "Режим: возможно Hyper-V (рекомендуется WSL2)"
                $warnCount++
            }
        }
    } else {
        Write-Fail "Docker: команда вернула пустой результат"
        $failCount++
    }
} catch {
    Write-Fail "Docker: ошибка - $_"
    $failCount++
}

# ═══════════════════════════════════════════════════════
# 3. Проверка Open WebUI
# ═══════════════════════════════════════════════════════
Write-Header "3. Open WebUI (контейнер)"

# docker-compose.yml
$composeFile = Join-Path $PWD "docker-compose.yml"
if (Test-Path $composeFile) {
    Write-Pass "docker-compose.yml: найден"
    $okCount++
} else {
    Write-Fail "docker-compose.yml: не найден в текущей папке"
    $failCount++
}

# Статус контейнера
try {
    $containerStatus = docker compose ps --format json 2>$null

    if ($containerStatus) {
        # Пытаемся распарсить JSON
        try {
            $containers = $containerStatus | ConvertFrom-Json

            foreach ($container in $containers) {
                $name = $container.Name
                $state = $container.State

                if ($state -eq "running") {
                    Write-Pass "Контейнер '$name': запущен"
                    $okCount++
                } else {
                    Write-Warn "Контейнер '$name': $state"
                    $warnCount++
                }
            }
        } catch {
            # Если не удалось распарсить JSON, используем старый метод
            if ($containerStatus -match '"State":"running"' -or $containerStatus -match 'running') {
                Write-Pass "Open WebUI: контейнер запущен"
                $okCount++
            } else {
                Write-Warn "Open WebUI: контейнер не в состоянии running"
                $warnCount++
            }
        }
    } else {
        Write-Warn "Open WebUI: контейнеры не найдены"
        $warnCount++
    }
} catch {
    Write-Fail "Open WebUI: ошибка проверки - $_"
    $failCount++
}

# Доступность веб-интерфейса
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Pass "WebUI: доступен (http://localhost:3000)"
        $okCount++
    }
} catch {
    Write-Warn "WebUI: не доступен на http://localhost:3000"
    $warnCount++
}

# ═══════════════════════════════════════════════════════
# 4. Проверка GPU
# ═══════════════════════════════════════════════════════
Write-Header "4. GPU (NVIDIA)"

try {
    $gpuInfo = nvidia-smi 2>$null
    if ($gpuInfo) {
        # Извлекаем информацию о GPU
        $gpuName = $gpuInfo | Select-String "NVIDIA" | Select-Object -First 1
        if ($gpuName) {
            Write-Pass "NVIDIA: $gpuName"
            $okCount++
        } else {
            Write-Pass "NVIDIA: GPU обнаружена"
            $okCount++
        }

        if ($Detailed) {
            # Память GPU
            $memoryInfo = $gpuInfo | Select-String "MiB"
            if ($memoryInfo) {
                Write-Info "Память: $memoryInfo"
            }
        }
    } else {
        Write-Warn "NVIDIA: nvidia-smi не вернула результат"
        $warnCount++
    }
} catch {
    Write-Warn "NVIDIA: не найдена (будет работать на CPU)"
    $warnCount++
}

# ═══════════════════════════════════════════════════════
# 5. Системные ресурсы
# ═══════════════════════════════════════════════════════
if ($Detailed) {
    Write-Header "5. Системные ресурсы"

    # RAM
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $usedRAM = $totalRAM - $freeRAM
    Write-Info "RAM: $($usedRAM) ГБ / $($totalRAM) ГБ свободно"

    # Диск
    $drive = Get-PSDrive C
    $totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 1)
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    Write-Info "Диск C: свободно $freeGB ГБ из $totalGB ГБ"
}

# ═══════════════════════════════════════════════════════
# Итоговый отчёт
# ═══════════════════════════════════════════════════════
Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              📊 РЕЗУЛЬТАТ ДИАГНОСТИКИ              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  ✅ OK: $okCount" -ForegroundColor Green
Write-Host "  ⚠️  WARN: $warnCount" -ForegroundColor Yellow
Write-Host "  ❌ FAIL: $failCount" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray

if ($failCount -eq 0) {
    Write-Host "🎉 Всё работает корректно!" -ForegroundColor Green
    exit 0
} elseif ($failCount -le 2) {
    Write-Host "⚠️  Есть проблемы, но частично работает" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "🚨 Критические проблемы, требуется исправление" -ForegroundColor Red
    exit 2
}
