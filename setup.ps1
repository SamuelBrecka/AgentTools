# ==============================================================================
# Setup script pre AgentTools (Windows / PowerShell)
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Nastavujem prostredie AgentTools    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$RepoRoot =$PSScriptRoot
Write-Host "Koreň repozitára: $RepoRoot" -ForegroundColor Gray

# ------------------------------------------------------------------------------
# 1. Inštalácia závislostí pre všetky MCP servery
# ------------------------------------------------------------------------------
$McpDir = Join-Path$RepoRoot "mcp"
if (Test-Path $McpDir) {
    Get-ChildItem -Path $McpDir -Directory | ForEach-Object {
        $ServerPath =$_.FullName
        $PackageJson = Join-Path$ServerPath "package.json"
        
        if (Test-Path $PackageJson) {
            Write-Host "`n[MCP] Inštalujem npm balíčky pre $($_.Name)..." -ForegroundColor Yellow
            Push-Location $ServerPath
            try {
                npm install
                Write-Host "[OK] $($_.Name) je pripravený." -ForegroundColor Green
            }
            catch {
                Write-Host "[CHYBA] Nepodarilo sa nainštalovať závislosti pre $($_.Name): $_" -ForegroundColor Red
            }
            finally {
                Pop-Location
            }
        }
    }
} else {
    Write-Host "[INFO] Priečinok 'mcp' neexistuje, preskakujem." -ForegroundColor DarkGray
}

# ------------------------------------------------------------------------------
# 2. Generovanie lokálneho mcp.json pre Antigravity
# ------------------------------------------------------------------------------
$AntigravityConfigDir = Join-Path $HOME ".gemini\antigravity-cli"
$SafeCommandServerJs = (Join-Path $McpDir "safe-command-mcp\server.js").Replace("\", "/")

if (Test-Path $AntigravityConfigDir) {
    Write-Host "`n[Config] Detegovaný Antigravity profil v $AntigravityConfigDir" -ForegroundColor Yellow
    
    $TargetMcpJson = Join-Path$AntigravityConfigDir "mcp.json"
    
    $McpConfig = @{
        mcpServers = @{
            "safe-commands" = @{
                command = "node"
                args = @($SafeCommandServerJs)
            }
        }
    } | ConvertTo-Json -Depth 5

    Set-Content -Path $TargetMcpJson -Value$McpConfig -Encoding UTF8
    Write-Host "[OK] Vygenerovaný konfiguračný súbor: $TargetMcpJson" -ForegroundColor Green
} else {
    Write-Host "[INFO] Antigravity profil (~/.gemini/antigravity-cli) nenájdený." -ForegroundColor DarkGray
}

# ------------------------------------------------------------------------------
# 3. Prelinkovanie globálnych pravidiel / skillov (voliteľné)
# ------------------------------------------------------------------------------
$SkillsSource = Join-Path$RepoRoot "skills"
$GeminiSkillsTarget = Join-Path$HOME ".gemini\skills"

if ((Test-Path $SkillsSource) -and (Test-Path (Join-Path$HOME ".gemini"))) {
    if (-not (Test-Path $GeminiSkillsTarget)) {
        New-Item -ItemType Directory -Path $GeminiSkillsTarget -Force | Out-Null
    }
    Write-Host "`n[Skills] Skilly sú pripravené v: $SkillsSource" -ForegroundColor Cyan
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   Setup bol úspešne dokončený!        " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green