[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [ValidateSet('Global', 'Project', 'All')]
    [string]$Mode = 'All',

    [string]$TargetPath,

    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,

    [string]$CopilotInstructionsRoot = (Join-Path $HOME '.copilot\instructions'),

    [string]$VscodeSettingsPath = $(if ($env:APPDATA) { Join-Path $env:APPDATA 'Code\User\settings.json' } else { Join-Path $HOME 'AppData\Roaming\Code\User\settings.json' }),

    [string]$VscodeUserPromptsRoot = $(if ($env:APPDATA) { Join-Path $env:APPDATA 'Code\User\prompts' } else { Join-Path $HOME 'AppData\Roaming\Code\User\prompts' }),

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Timestamp {
    Get-Date -Format 'yyyyMMdd-HHmmss'
}

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Backup-File {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $backupPath = '{0}.bak-{1}' -f $Path, (Get-Timestamp)
    Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    return $backupPath
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    Ensure-Directory -Path (Split-Path -Parent $Path)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Copy-TemplateFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [switch]$OverwriteExisting
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "找不到來源檔: $Source"
    }

    Ensure-Directory -Path (Split-Path -Parent $Destination)

    if (Test-Path -LiteralPath $Destination) {
        if (-not $OverwriteExisting) {
            return $false
        }

        [void](Backup-File -Path $Destination)
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    return $true
}

function Ensure-JsoncSetting {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$ValueExpression
    )

    Ensure-Directory -Path (Split-Path -Parent $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        $initial = @(
            '{',
            ('  "{0}": {1}' -f $Key, $ValueExpression),
            '}'
        )
        [System.IO.File]::WriteAllLines($Path, $initial, [System.Text.UTF8Encoding]::new($false))
        return
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.AddRange([string[]](Get-Content -LiteralPath $Path))

    $pattern = ('^\s*"{0}"\s*:' -f [regex]::Escape($Key))
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match $pattern) {
            $indent = [regex]::Match($lines[$index], '^\s*').Value
            $comma = if ($lines[$index].TrimEnd().EndsWith(',')) { ',' } else { '' }
            $lines[$index] = '{0}"{1}": {2}{3}' -f $indent, $Key, $ValueExpression, $comma
            [System.IO.File]::WriteAllLines($Path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
            return
        }
    }

    $closingIndex = -1
    for ($index = $lines.Count - 1; $index -ge 0; $index--) {
        if ($lines[$index].Trim() -eq '}') {
            $closingIndex = $index
            break
        }
    }

    if ($closingIndex -lt 0) {
        $lines.Add('  "{0}": {1}' -f $Key, $ValueExpression)
        $lines.Add('}')
        [System.IO.File]::WriteAllLines($Path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
        return
    }

    $previousIndex = -1
    for ($index = $closingIndex - 1; $index -ge 0; $index--) {
        $trimmed = $lines[$index].Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('//') -or $trimmed.StartsWith('/*') -or $trimmed.StartsWith('*')) {
            continue
        }
        $previousIndex = $index
        break
    }

    if ($previousIndex -ge 0 -and -not $lines[$previousIndex].TrimEnd().EndsWith(',')) {
        $lines[$previousIndex] = $lines[$previousIndex].TrimEnd() + ','
    }

    $indent = if ($previousIndex -ge 0) { [regex]::Match($lines[$previousIndex], '^\s*').Value } else { '  ' }
    $lines.Insert($closingIndex, ('{0}"{1}": {2}' -f $indent, $Key, $ValueExpression))
    [System.IO.File]::WriteAllLines($Path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
}

function Get-ArchitectureTemplate {
@'
# Architecture

## Goals
- Describe the primary goal of the project.

## Structure
- Describe the top-level folders and module boundaries.

## Conventions
- Describe naming, ownership, and prohibited patterns.

## Dependencies
- List important runtime and build dependencies.

## Testing
- Describe the expected test and verification workflow.
'@
}

function Get-HandoffTemplate {
@'
# HANDOFF

## 目前狀態
- 

## 剩餘計畫
- 

## 卡關與疑問
- 

## 相關檔案與指令
- 
'@
}

function Install-GlobalPreferences {
    $sourceUserInstructions = Join-Path $RepoRoot 'user-instructions.md'
    if (-not (Test-Path -LiteralPath $sourceUserInstructions)) {
        throw "找不到來源檔: $sourceUserInstructions"
    }

    Ensure-Directory -Path $CopilotInstructionsRoot
    Copy-Item -LiteralPath $sourceUserInstructions -Destination (Join-Path $CopilotInstructionsRoot 'user-instructions.md') -Force

    Ensure-Directory -Path $VscodeUserPromptsRoot
    foreach ($prompt in 'init.prompt.md', 'resume.prompt.md') {
        $promptSource = Join-Path $RepoRoot ".github\prompts\$prompt"
        if (Test-Path -LiteralPath $promptSource) {
            Copy-Item -LiteralPath $promptSource -Destination (Join-Path $VscodeUserPromptsRoot $prompt) -Force
        }
    }

    Ensure-JsoncSetting -Path $VscodeSettingsPath -Key 'chat.useAgentsMdFile' -ValueExpression 'true'
    Ensure-JsoncSetting -Path $VscodeSettingsPath -Key 'chat.useNestedAgentsMdFiles' -ValueExpression 'true'
    Ensure-JsoncSetting -Path $VscodeSettingsPath -Key 'chat.promptFilesLocations' -ValueExpression '{ ".github/prompts": true }'
    Ensure-JsoncSetting -Path $VscodeSettingsPath -Key 'chat.instructionsFilesLocations' -ValueExpression '{ ".github/instructions": true }'
    Ensure-JsoncSetting -Path $VscodeSettingsPath -Key 'chat.useCustomizationsInParentRepositories' -ValueExpression 'true'

    [pscustomobject]@{
        CopilotInstructionsPath = (Join-Path $CopilotInstructionsRoot 'user-instructions.md')
        VscodeSettingsPath = $VscodeSettingsPath
        VscodeUserPromptsRoot = $VscodeUserPromptsRoot
    }
}

function Install-ProjectBootstrap {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    Ensure-Directory -Path $ProjectRoot

    $files = @(
        @{ Source = (Join-Path $RepoRoot 'AGENTS.md'); Destination = (Join-Path $ProjectRoot 'AGENTS.md') },
        @{ Source = (Join-Path $RepoRoot '.github\prompts\resume.prompt.md'); Destination = (Join-Path $ProjectRoot '.github\prompts\resume.prompt.md') },
        @{ Source = (Join-Path $RepoRoot '.github\prompts\init.prompt.md'); Destination = (Join-Path $ProjectRoot '.github\prompts\init.prompt.md') },
        @{ Source = (Join-Path $RepoRoot '.github\instructions\guardrails.instructions.md'); Destination = (Join-Path $ProjectRoot '.github\instructions\guardrails.instructions.md') },
        @{ Source = (Join-Path $RepoRoot '.github\hooks\high-risk-guard.json'); Destination = (Join-Path $ProjectRoot '.github\hooks\high-risk-guard.json') },
        @{ Source = (Join-Path $RepoRoot '.github\hooks\context-handoff.json'); Destination = (Join-Path $ProjectRoot '.github\hooks\context-handoff.json') },
        @{ Source = (Join-Path $RepoRoot '.github\hooks\scripts\high_risk_guard.py'); Destination = (Join-Path $ProjectRoot '.github\hooks\scripts\high_risk_guard.py') },
        @{ Source = (Join-Path $RepoRoot '.github\hooks\scripts\handoff_reminder.py'); Destination = (Join-Path $ProjectRoot '.github\hooks\scripts\handoff_reminder.py') }
    )

    foreach ($pair in $files) {
        if ((Test-Path -LiteralPath $pair.Destination) -and -not $Force) {
            continue
        }

        [void](Copy-TemplateFile -Source $pair.Source -Destination $pair.Destination -OverwriteExisting:($Force -or -not (Test-Path -LiteralPath $pair.Destination)))
    }

    $architecturePath = Join-Path $ProjectRoot 'docs\architecture.md'
    if ((-not (Test-Path -LiteralPath $architecturePath)) -or $Force) {
        Write-Utf8NoBom -Path $architecturePath -Content (Get-ArchitectureTemplate)
    }

    $handoffPath = Join-Path $ProjectRoot '.handoffs\HANDOFF.md'
    if ((-not (Test-Path -LiteralPath $handoffPath)) -or $Force) {
        Write-Utf8NoBom -Path $handoffPath -Content (Get-HandoffTemplate)
    }

    $gitignorePath = Join-Path $ProjectRoot '.gitignore'
    $gitignoreLines = @(
        '# hook 稽核 log(執行時才產生,不進版控)',
        '*.log',
        '.github/hooks/*.log',
        '',
        '# 安裝 bootstrap 的暫存備份',
        '*.bak-*'
    )

    if (Test-Path -LiteralPath $gitignorePath) {
        $existing = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        foreach ($line in [string[]](Get-Content -LiteralPath $gitignorePath)) {
            [void]$existing.Add($line)
        }

        $updatedLines = [System.Collections.Generic.List[string]]::new()
        [void]$updatedLines.AddRange([string[]](Get-Content -LiteralPath $gitignorePath))
        foreach ($line in $gitignoreLines) {
            if (-not $existing.Contains($line)) {
                [void]$updatedLines.Add($line)
            }
        }

        [void](Backup-File -Path $gitignorePath)
        [System.IO.File]::WriteAllLines($gitignorePath, [string[]]$updatedLines, [System.Text.UTF8Encoding]::new($false))
    } else {
        [System.IO.File]::WriteAllLines($gitignorePath, $gitignoreLines, [System.Text.UTF8Encoding]::new($false))
    }

    [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        ArchitecturePath = $architecturePath
        HandoffPath = $handoffPath
    }
}

$results = [System.Collections.Generic.List[object]]::new()

if ($Mode -in @('Global', 'All')) {
    $proceedGlobal = $Force
    if (-not $proceedGlobal) {
        Write-Host '即將安裝「全域偏好」,會修改本機 VS Code 使用者設定與 prompts:'
        Write-Host "  settings: $VscodeSettingsPath"
        Write-Host "  prompts : $VscodeUserPromptsRoot"
        Write-Host "  copilot : $CopilotInstructionsRoot"
        $answer = Read-Host '確定要套用到本機嗎?(y/N)'
        $proceedGlobal = $answer -match '^(y|yes)$'
    }
    if (-not $proceedGlobal) {
        Write-Host '已略過全域偏好安裝。'
    }
    elseif ($PSCmdlet.ShouldProcess($VscodeSettingsPath, 'Install global preferences')) {
        $results.Add((Install-GlobalPreferences))
    }
}

if ($Mode -in @('Project', 'All')) {
    if (-not $TargetPath) {
        throw 'Mode=Project/All 時必須提供 -TargetPath。'
    }

    if ($PSCmdlet.ShouldProcess($TargetPath, 'Install project bootstrap')) {
        $results.Add((Install-ProjectBootstrap -ProjectRoot $TargetPath))
    }
}

$results | ConvertTo-Json -Depth 6
