#Requires -Version 7.0
# Checks a machine set up by windows/setup.ps1. Used by CI; also handy locally.
#   pwsh windows/verify.ps1            # core checks
#   pwsh windows/verify.ps1 -Extras    # also check the extras
[CmdletBinding()]
param([switch]$Extras)

$ErrorActionPreference = 'Stop'
$Dotfiles = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = [System.Collections.Generic.List[string]]::new()

# winget writes PATH to the registry; pick it up even if this shell is older.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
            "$HOME\.local\bin;$HOME\.cargo\bin;$HOME\go\bin"

function Test-Check([string]$Name, [scriptblock]$Check) {
    try {
        if (& $Check) { Write-Host "  ok    $Name" -ForegroundColor Green; return }
        $failures.Add($Name); Write-Host "  FAIL  $Name" -ForegroundColor Red
    } catch {
        $failures.Add("$Name ($_)"); Write-Host "  FAIL  $Name : $_" -ForegroundColor Red
    }
}

Write-Host '==> Commands'
$commands = 'git', 'pwsh', 'delta', 'lazygit', 'rg', 'fd', 'fzf', 'jq', 'fastfetch',
            'oh-my-posh', 'nvim', 'go', 'gopls', 'dlv', 'gofumpt', 'golangci-lint',
            'uv', 'ruff', 'rustup', 'cargo', 'fnm', 'jj', 'direnv', 'gh', 'mkcert', 'age', 'sops',
            'claude', 'codex'
if ($Extras) {
    $commands += 'zoxide', 'bat', 'eza', 'dust', 'duf', 'btm', 'xh', 'hyperfine', 'just',
                 'shellcheck', 'yq', 'gping', 'procs', 'sd', 'tldr'
}
foreach ($c in $commands) { Test-Check $c { [bool](Get-Command $c -ErrorAction SilentlyContinue) } }

# node/npm and opencode come from fnm's default alias
fnm env --shell powershell | Out-String | Invoke-Expression
foreach ($c in 'node', 'npm', 'opencode') { Test-Check $c { [bool](Get-Command $c -ErrorAction SilentlyContinue) } }

Write-Host '==> Links'
$docs = [Environment]::GetFolderPath('MyDocuments')
$links = @{
    (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1') = Join-Path $Dotfiles 'windows\Microsoft.PowerShell_profile.ps1'
    (Join-Path $HOME '.ssh\config')                                  = Join-Path $Dotfiles 'windows\ssh\config'
    (Join-Path $env:LOCALAPPDATA 'nvim')                             = Join-Path $Dotfiles 'nvim'
    (Join-Path $env:APPDATA 'jj\config.toml')                        = Join-Path $Dotfiles 'jj\config.toml'
}
foreach ($l in $links.GetEnumerator()) {
    Test-Check $l.Key { (Get-Item $l.Key -Force).Target -eq $l.Value }
}

Write-Host '==> Git config'
Test-Check 'git includes git/.gitconfig (core.pager = delta)' { (git config --global --includes core.pager) -eq 'delta' }
Test-Check 'git autocrlf = true (Windows override)' { (git config --global core.autocrlf) -eq 'true' }

Write-Host '==> Profile'
$profilePath = Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1'
# Load the profile in a fresh, non-interactive shell; any error fails the check.
$out = pwsh -NoProfile -NonInteractive -Command "`$ErrorActionPreference='Stop'; . '$profilePath'; if (-not (Get-Command gs -ErrorAction SilentlyContinue)) { throw 'git functions missing' }; 'PROFILE_OK'" 2>&1
Test-Check 'profile loads without errors' { ($out -join "`n") -match 'PROFILE_OK' }
if (-not (($out -join "`n") -match 'PROFILE_OK')) { $out | ForEach-Object { Write-Host "        $_" } }
Test-Check 'oh-my-posh theme parses' { (Get-Content (Join-Path $Dotfiles 'windows\ohmyposh\theme.omp.json') -Raw | ConvertFrom-Json).blocks.Count -gt 0 }

if ($failures.Count) {
    Write-Host "`n$($failures.Count) check(s) failed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "`nAll checks passed." -ForegroundColor Green
