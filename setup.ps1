# ==============================================================================
# Setup script pre AgentTools (Windows / PowerShell)
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Nastavujem prostredie AgentTools    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$RepoRoot = $PSScriptRoot
Write-Host "Koreň repozitára: $RepoRoot" -ForegroundColor Gray

# ------------------------------------------------------------------------------
# 1. Inštalácia závislostí pre všetky MCP servery
# ------------------------------------------------------------------------------
$McpDir = Join-Path $RepoRoot "mcp"
if (Test-Path $McpDir) {
    Get-ChildItem -Path $McpDir -Directory | ForEach-Object {
        $ServerPath = $_.FullName
        $PackageJson = Join-Path $ServerPath "package.json"
        
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
# 2. Konfigurácia MCP serverov pre Antigravity (~/.gemini/config/mcp_config.json)
# ------------------------------------------------------------------------------
$GeminiConfigDir = Join-Path $HOME ".gemini\config"
if (-not (Test-Path $GeminiConfigDir)) {
    New-Item -ItemType Directory -Path $GeminiConfigDir -Force | Out-Null
    Write-Host "`n[Config] Vytvorený adresár: $GeminiConfigDir" -ForegroundColor Cyan
}

$SafeCommandServerJs = (Join-Path $McpDir "safe-command-mcp\server.js").Replace("\", "/")
$TargetMcpConfigJson = Join-Path $GeminiConfigDir "mcp_config.json"

$McpConfigData = [ordered]@{}
$McpServersHash = [ordered]@{}

if (Test-Path $TargetMcpConfigJson) {
    try {
        $RawContent = Get-Content -Raw -Path $TargetMcpConfigJson -Encoding UTF8
        if (-not [string]::IsNullOrWhiteSpace($RawContent)) {
            $Parsed = $RawContent | ConvertFrom-Json
            if ($null -ne $Parsed.mcpServers) {
                $Parsed.mcpServers.PSObject.Properties | ForEach-Object {
                    $McpServersHash[$_.Name] = $_.Value
                }
            }
        }
    } catch {
        Write-Host "[VAROVANIE] Nepodarilo sa prečítať existujúci $TargetMcpConfigJson, vytvorí sa nový: $_" -ForegroundColor Yellow
    }
}

$McpServersHash["safe-commands"] = [ordered]@{
    command = "node"
    args = @($SafeCommandServerJs)
}
$McpConfigData["mcpServers"] = $McpServersHash

$McpConfigJsonString = $McpConfigData | ConvertTo-Json -Depth 10
Set-Content -Path $TargetMcpConfigJson -Value $McpConfigJsonString -Encoding UTF8
Write-Host "`n[Config] MCP server safe-commands zaregistrovaný v: $TargetMcpConfigJson" -ForegroundColor Green

# Upozornenie na starý nepoužívaný súbor mcp.json
$LegacyMcpJson = Join-Path $HOME ".gemini\antigravity-cli\mcp.json"
if (Test-Path $LegacyMcpJson) {
    Write-Host "[INFO] Zastaraný konfiguračný súbor $LegacyMcpJson bol nahradený $TargetMcpConfigJson." -ForegroundColor DarkGray
}

# ------------------------------------------------------------------------------
# 3. Registrácia globálnych skillov pre Antigravity (~/.gemini/config/skills.json a ~/.gemini/skills)
# ------------------------------------------------------------------------------
$SkillsSource = Join-Path $RepoRoot "skills"
$SkillsSourceNorm = $SkillsSource.Replace("\", "/")
$TargetSkillsJson = Join-Path $GeminiConfigDir "skills.json"

if (Test-Path $SkillsSource) {
    # a) Registrácia cez skills.json
    $SkillsEntries = [System.Collections.ArrayList]@()
    if (Test-Path $TargetSkillsJson) {
        try {
            $RawSkillsContent = Get-Content -Raw -Path $TargetSkillsJson -Encoding UTF8
            if (-not [string]::IsNullOrWhiteSpace($RawSkillsContent)) {
                $ParsedSkills = $RawSkillsContent | ConvertFrom-Json
                if ($null -ne $ParsedSkills.entries) {
                    foreach ($entry in $ParsedSkills.entries) {
                        $null = $SkillsEntries.Add([ordered]@{ path = $entry.path })
                    }
                }
            }
        } catch {
            $SkillsEntries = [System.Collections.ArrayList]@()
        }
    }

    $AlreadyPresent = $false
    foreach ($entry in $SkillsEntries) {
        if ($entry.path -eq $SkillsSourceNorm -or $entry.path -eq $SkillsSource) {
            $AlreadyPresent = $true
            break
        }
    }
    if (-not $AlreadyPresent) {
        $null = $SkillsEntries.Add([ordered]@{ path = $SkillsSourceNorm })
    }

    $SkillsConfigData = [ordered]@{
        entries = $SkillsEntries
    }
    $SkillsJsonString = $SkillsConfigData | ConvertTo-Json -Depth 10
    Set-Content -Path $TargetSkillsJson -Value $SkillsJsonString -Encoding UTF8
    Write-Host "`n[Skills] Skilly zaregistrované v: $TargetSkillsJson" -ForegroundColor Green

    # b) Link / mirror do ~/.gemini/skills pre spätnú kompatibilitu
    $GeminiSkillsTarget = Join-Path $HOME ".gemini\skills"
    if (-not (Test-Path $GeminiSkillsTarget)) {
        try {
            New-Item -ItemType Junction -Path $GeminiSkillsTarget -Target $SkillsSource | Out-Null
            Write-Host "[OK] Vytvorený odkaz pre skilly: $GeminiSkillsTarget -> $SkillsSource" -ForegroundColor Green
        } catch {
            Copy-Item -Path $SkillsSource -Destination $GeminiSkillsTarget -Recurse -Force
            Write-Host "[OK] Skilly skopírované do: $GeminiSkillsTarget" -ForegroundColor Green
        }
    } else {
        Write-Host "[Skills] Priečinok alebo odkaz $GeminiSkillsTarget je aktívny." -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------------------
# 4. Globálne pravidlá pre Antigravity (~/.gemini/config/AGENTS.md)
# ------------------------------------------------------------------------------
$RulesSource = Join-Path $RepoRoot "rules\AGENTS.md"
$GlobalRulesTarget = Join-Path $GeminiConfigDir "AGENTS.md"

if (Test-Path $RulesSource) {
    Copy-Item -Path $RulesSource -Destination $GlobalRulesTarget -Force
    Write-Host "`n[Rules] Globálne pravidlá synchronizované do: $GlobalRulesTarget" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   Setup bol úspešne dokončený!        " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
