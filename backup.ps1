<#
.SYNOPSIS
    Автоматический бэкап Ollama и Open WebUI
.DESCRIPTION
    Создаёт резервную копию моделей Ollama, данных Open WebUI и конфигурации.
    Удаляет бэкапы старше 7 дней.
.NOTES
    Рекомендуется запускать через Планировщик задач ежедневно в 03:00
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$BackupRoot = "$PWD\backup",

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 7
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
Write-Host "║          💾 РЕЗЕРВНОЕ КОПИРОВАНИЕ                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$startTime = Get-Date
Write-Step "Начало бэкапа: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))"

# ═══════════════════════════════════════════════════════
# 1. Создание папки бэкапа
# ═══════════════════════════════════════════════════════
$backupDate = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupPath = Join-Path $BackupRoot $backupDate

Write-Step "Создание папки бэкапа..."
try {
    New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
    Write-OK "Папка создана: $backupPath"
} catch {
    Write-Fail "Ошибка создания папки: $_"
    exit 1
}

# ═══════════════════════════════════════════════════════
# 2. Бэкап моделей Ollama
# ═══════════════════════════════════════════════════════
$ollamaPath = "$env:USERPROFILE\.ollama"
$ollamaBackupPath = Join-Path $backupPath "ollama"

Write-Step "Бэкап Ollama ($ollamaPath)..."

if (Test-Path $ollamaPath) {
    try {
        # Проверяем размер папки
        $ollamaSize = (Get-ChildItem $ollamaPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $ollamaSizeGB = [math]::Round($ollamaSize / 1GB, 2)
        Write-Host "  📦 Размер Ollama: $ollamaSizeGB ГБ" -ForegroundColor DarkGray

        robocopy $ollamaPath $ollamaBackupPath /E /MT:8 /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP

        if ($LASTEXITCODE -le 7) {
            Write-OK "Ollama скопирован ($ollamaSizeGB ГБ)"
        } else {
            Write-Warn "Ollama скопирован с предупреждениями (код: $LASTEXITCODE)"
        }
    } catch {
        Write-Fail "Ошибка бэкапа Ollama: $_"
    }
} else {
    Write-Warn "Папка Ollama не найдена: $ollamaPath"
}

# ═══════════════════════════════════════════════════════
# 3. Бэкап данных Open WebUI
# ═══════════════════════════════════════════════════════
$webuiPath = Join-Path $PWD "webui-data"
$webuiBackupPath = Join-Path $backupPath "webui"

Write-Step "Бэкап Open WebUI ($webuiPath)..."

if (Test-Path $webuiPath) {
    try {
        # Проверяем размер папки
        $webuiSize = (Get-ChildItem $webuiPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $webuiSizeGB = [math]::Round($webuiSize / 1GB, 2)
        Write-Host "  📦 Размер WebUI: $webuiSizeGB ГБ" -ForegroundColor DarkGray

        robocopy $webuiPath $webuiBackupPath /E /MT:8 /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP

        if ($LASTEXITCODE -le 7) {
            Write-OK "Open WebUI скопирован ($webuiSizeGB ГБ)"
        } else {
            Write-Warn "Open WebUI скопирован с предупреждениями (код: $LASTEXITCODE)"
        }
    } catch {
        Write-Fail "Ошибка бэкапа Open WebUI: $_"
    }
} else {
    Write-Warn "Папка WebUI не найдена: $webuiPath"
}

# ═══════════════════════════════════════════════════════
# 4. Бэкап конфигурации
# ═══════════════════════════════════════════════════════
Write-Step "Бэкап конфигурации..."

# docker-compose.yml
$composeFile = Join-Path $PWD "docker-compose.yml"
if (Test-Path $composeFile) {
    try {
        Copy-Item $composeFile $backupPath -Force
        Write-OK "docker-compose.yml скопирован"
    } catch {
        Write-Warn "Ошибка копирования docker-compose.yml"
    }
} else {
    Write-Warn "docker-compose.yml не найден"
}

# config.json Ollama
$ollamaConfig = "$env:USERPROFILE\.ollama\config.json"
if (Test-Path $ollamaConfig) {
    try {
        $ollamaConfigBackup = Join-Path $backupPath "ollama-config.json"
        Copy-Item $ollamaConfig $ollamaConfigBackup -Force
        Write-OK "config.json (Ollama) скопирован"
    } catch {
        Write-Warn "Ошибка копирования config.json"
    }
} else {
    Write-Warn "config.json Ollama не найден"
}

# ═══════════════════════════════════════════════════════
# 5. Итоговый размер бэкапа
# ═══════════════════════════════════════════════════════
Write-Step "Подсчёт размера бэкапа..."

try {
    $backupSize = (Get-ChildItem $backupPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $backupSizeGB = [math]::Round($backupSize / 1GB, 2)
    Write-OK "Общий размер бэкапа: $backupSizeGB ГБ"
} catch {
    Write-Warn "Не удалось подсчитать размер бэкапа"
}

# ═══════════════════════════════════════════════════════
# 6. Очистка старых бэкапов
# ═══════════════════════════════════════════════════════
Write-Step "Очистка бэкапов старше $RetentionDays дней..."

try {
    $oldBackups = Get-ChildItem $BackupRoot -Directory |
        Where-Object {
            $backupDate = $_.Name -replace '_.*', ''
            try {
                $date = [datetime]::ParseExact($backupDate, 'yyyy-MM-dd', $null)
                $date -lt (Get-Date).AddDays(-$RetentionDays)
            } catch {
                $false
            }
        }

    if ($oldBackups.Count -gt 0) {
        foreach ($backup in $oldBackups) {
            Write-Host "  🗑️  Удаление: $($backup.Name)" -ForegroundColor DarkGray
            Remove-Item $backup.FullName -Recurse -Force
        }
        Write-OK "Удалено бэкапов: $($oldBackups.Count)"
    } else {
        Write-OK "Старых бэкапов не найдено"
    }
} catch {
    Write-Warn "Ошибка очистки старых бэкапов: $_"
}

# ═══════════════════════════════════════════════════════
# 7. Итоговая информация
# ═══════════════════════════════════════════════════════
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          ✅ БЭКАП ЗАВЕРШЁН УСПЕШНО!                ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📋 РЕЗУЛЬТАТ:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "   📁 Путь: $backupPath" -ForegroundColor White
Write-Host "   ⏱️  Время: $([math]::Round($duration, 1)) сек" -ForegroundColor White
Write-Host "   💾 Размер: $backupSizeGB ГБ" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray
