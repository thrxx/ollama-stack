<#
.SYNOPSIS
    Полная установка стека: Ollama + Docker + Open WebUI
.DESCRIPTION
    Автоматизирует установку всех компонентов локального ИИ-ассистента
    согласно руководству из guide.md
.NOTES
    Запускать от имени администратора!
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$InstallPath = "$PWD",

    [Parameter(Mandatory = $false)]
    [switch]$SkipWSL
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

# ═══════════════════════════════════════════════════════
# 0. Проверка прав администратора
# ═══════════════════════════════════════════════════════
Write-Step "Проверка прав администратора..."

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fail "Запустите скрипт от имени администратора!"
    Write-Warn "Правый клик → Запуск от имени администратора"
    exit 1
}
Write-OK "Права администратора подтверждены"

# ═══════════════════════════════════════════════════════
# 1. Проверка системных требований
# ═══════════════════════════════════════════════════════
Write-Step "Проверка системных требований..."

# Виртуализация
$sysinfo = systeminfo 2>$null | Select-String "Virtualization"
if ($sysinfo -match "Yes") {
    Write-OK "Виртуализация включена"
} else {
    Write-Warn "Не удалось определить статус виртуализации"
    Write-Warn "Убедитесь, что VT-x/AMD-V включён в BIOS"
}

# NVIDIA GPU
try {
    nvidia-smi 2>$null | Out-Null
    Write-OK "NVIDIA GPU обнаружена"
} catch {
    Write-Warn "NVIDIA GPU не найдена (будет работать на CPU)"
}

# Свободное место
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 1)
if ($freeGB -lt 50) {
    Write-Warn "Мало свободного места: $freeGB ГБ (рекоменуется >50 ГБ)"
} else {
    Write-OK "Свободное место на C: $freeGB ГБ"
}

# ═══════════════════════════════════════════════════════
# 2. Установка WSL2
# ═══════════════════════════════════════════════════════
if ($SkipWSL) {
    Write-Step "Пропуск установки WSL2 (ключ -SkipWSL)"
} else {
    Write-Step "Установка WSL2..."

    try {
        $wslInstalled = wsl --status 2>$null
        if ($wslInstalled) {
            Write-OK "WSL2 уже установлен"
        } else {
            Write-Host "  📦 Установка WSL2 + Ubuntu 22.04..." -ForegroundColor DarkGray
            wsl --install -d Ubuntu-22.04 --no-launch
            Write-OK "WSL2 установлен"
            Write-Warn "Требуется перезагрузка после завершения установки!"
        }
    } catch {
        Write-Fail "Ошибка установки WSL2: $_"
        exit 1
    }
}

# ═══════════════════════════════════════════════════════
# 3. Установка Ollama
# ═══════════════════════════════════════════════════════
Write-Step "Установка Ollama..."

if (Get-Service -Name "Ollama" -ErrorAction SilentlyContinue) {
    Write-OK "Ollama уже установлен"
} else {
    try {
        $installer = "$env:TEMP\OllamaSetup.exe"
        Write-Host "  📥 Загрузка установщика Ollama..." -ForegroundColor DarkGray

        Invoke-WebRequest -Uri "https://ollama.com/download/windows" -OutFile $installer -UseBasicParsing
        Write-Host "  📦 Запуск установщика..." -ForegroundColor DarkGray
        Start-Process -FilePath $installer -Wait -NoNewWindow

        Write-OK "Ollama установлен"
    } catch {
        Write-Fail "Ошибка установки Ollama: $_"
        Write-Warn "Скачайте вручную: https://ollama.com/download/windows"
        exit 1
    }
}

# ═══════════════════════════════════════════════════════
# 4. Установка Docker Desktop
# ═══════════════════════════════════════════════════════
Write-Step "Установка Docker Desktop..."

try {
    docker info 2>$null | Out-Null
    Write-OK "Docker уже установлен и работает"
} catch {
    try {
        $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
        Write-Host "  📥 Загрузка установщика Docker Desktop..." -ForegroundColor DarkGray

        Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile $dockerInstaller -UseBasicParsing
        Write-Host "  📦 Запуск установщика Docker..." -ForegroundColor DarkGray
        Start-Process -FilePath $dockerInstaller -Wait -NoNewWindow

        Write-OK "Docker Desktop установлен"
        Write-Warn "Запустите Docker Desktop и дождитесь зелёного индикатора"
    } catch {
        Write-Fail "Ошибка установки Docker: $_"
        Write-Warn "Скачайте вручную: https://www.docker.com/products/docker-desktop"
        exit 1
    }
}

# ═══════════════════════════════════════════════════════
# 5. Создание структуры проекта
# ═══════════════════════════════════════════════════════
Write-Step "Создание структуры проекта в: $InstallPath"

try {
    $webuiDataPath = Join-Path $InstallPath "webui-data"
    New-Item -ItemType Directory -Force -Path $webuiDataPath | Out-Null
    Write-OK "Создана папка: webui-data"
} catch {
    Write-Fail "Ошибка создания структуры: $_"
    exit 1
}

# ═══════════════════════════════════════════════════════
# 6. Создание docker-compose.yml
# ═══════════════════════════════════════════════════════
Write-Step "Создание docker-compose.yml..."

$dockerComposePath = Join-Path $InstallPath "docker-compose.yml"
$dockerComposeContent = @'
version: "3.8"

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped

    # Порт доступа к веб-интерфейсу
    ports:
      - "3000:8080"

    # Переменные окружения
    environment:
      # Адрес локального Ollama (специальный хост для Docker на Windows)
      - OLLAMA_BASE_URL=http://host.docker.internal:11434

      # Приватность: отключение телеметрии
      - DISABLE_ANALYTICS=true

      # RAG: работа с документами
      - ENABLE_RAG=true
      - RAG_TOP_K=5
      - RAG_EMBEDDING_MODEL=all-minilm:l6-v2

      # Параметры по умолчанию для моделей
      - DEFAULT_CONTEXT_LENGTH=8192
      - DEFAULT_TEMPERATURE=0.3
      - MAX_TOKENS=4096

    # Сохранение данных: чаты, пользователи, настройки
    volumes:
      - ./webui-data:/app/backend/data

    # Ограничение ресурсов контейнера (опционально)
    deploy:
      resources:
        limits:
          memory: 4G
'@

try {
    Set-Content -Path $dockerComposePath -Value $dockerComposeContent -Encoding UTF8
    Write-OK "Создан docker-compose.yml"
} catch {
    Write-Fail "Ошибка создания docker-compose.yml: $_"
    exit 1
}

# ═══════════════════════════════════════════════════════
# 7. Создание config.json для Ollama
# ═══════════════════════════════════════════════════════
Write-Step "Создание config.json для Ollama..."

$ollamaConfigDir = "$env:USERPROFILE\.ollama"
$ollamaConfigPath = Join-Path $ollamaConfigDir "config.json"

if (-not (Test-Path $ollamaConfigDir)) {
    New-Item -ItemType Directory -Force -Path $ollamaConfigDir | Out-Null
}

$ollamaConfigContent = @{
    num_gpu    = 99
    num_thread = 12
    main_gpu   = 0
    low_vram   = $false
    num_batch  = 512
} | ConvertTo-Json

try {
    Set-Content -Path $ollamaConfigPath -Value $ollamaConfigContent -Encoding UTF8
    Write-OK "Создан config.json в: $ollamaConfigPath"
} catch {
    Write-Fail "Ошибка создания config.json: $_"
    exit 1
}

# ═══════════════════════════════════════════════════════
# 8. Итоговая информация
# ═══════════════════════════════════════════════════════
Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          ✅ УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!            ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📋 СЛЕДУЮЩИЕ ШАГИ:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "1. 🔄 Перезагрузите компьютер" -ForegroundColor White
Write-Host "2. 🐳 Запустите Docker Desktop и дождитесь ✅" -ForegroundColor White
Write-Host "3. 🦙 Запустите Ollama (служба Windows)" -ForegroundColor White
Write-Host "4. 🚀 Запустите: .\start-assistant.ps1" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray

Write-Warn "После перезагрузки проверьте: docker info"
Write-Warn "Если Docker не работает — запустите Docker Desktop вручную"
