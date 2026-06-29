[CmdletBinding()]
param(
    [string]$InstallDir = (Join-Path $HOME 'copilot-vscode-agent-rules'),
    [string]$RepoUrl = 'https://github.com/lucaslanintel/copilot-vscode-agent-rules.git',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

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

$args = @('-Mode', 'Global')
if ($Force) { $args += '-Force' }
& $bootstrap @args

Write-Host ''
Write-Host '完成:全域偏好已安裝,新專案 Chat 直接喊 /init 即可套規範。'
Write-Host "套到專案:pwsh -File `"$bootstrap`" -Mode Project -TargetPath <專案路徑>"
