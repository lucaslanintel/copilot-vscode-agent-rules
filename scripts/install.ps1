# Supports both direct execution and `iex (iwr ...).Content` remote run.
# When run remotely, $InstallDir / $Force can be pre-set as env vars:
#   $env:CVAR_DIR = 'C:\custom\path'; $env:CVAR_FORCE = '1'; iex (iwr ...).Content
[CmdletBinding()]
param(
    [string]$InstallDir = $(if ($env:CVAR_DIR) { $env:CVAR_DIR } else { Join-Path $HOME 'copilot-vscode-agent-rules' }),
    [string]$RepoUrl = 'https://github.com/lucaslanintel/copilot-vscode-agent-rules.git',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# When invoked via iex the param block still applies; resolve Force from env if needed.
if (-not $Force -and $env:CVAR_FORCE -eq '1') { $Force = $true }

function Test-Cmd { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

if (-not (Test-Cmd git)) { throw '需要 git,請先安裝 git。' }

# 取得 / 更新 repo(private 優先用 gh,public 可直接 git clone)
if (Test-Path (Join-Path $InstallDir '.git')) {
    Write-Host "更新既有 repo: $InstallDir"
    git -C $InstallDir pull --ff-only
} else {
    Write-Host "Clone 到: $InstallDir"
    if (Test-Cmd gh) {
        gh repo clone lucaslanintel/copilot-vscode-agent-rules $InstallDir
    } else {
        git clone $RepoUrl $InstallDir
    }
}

# 一次裝好全域偏好 + 全域 /init、/resume
$bootstrap = Join-Path $InstallDir 'scripts\bootstrap.ps1'
if (-not (Test-Path $bootstrap)) { throw "找不到 bootstrap: $bootstrap" }

$bsArgs = @{ Mode = 'Global' }
if ($Force) { $bsArgs.Force = $true }
& $bootstrap @bsArgs

Write-Host ''
Write-Host '完成:全域偏好已安裝,新專案 Chat 直接喊 /init 即可套規範。'
Write-Host "套到專案:pwsh -File `"$bootstrap`" -Mode Project -TargetPath <專案路徑>"
