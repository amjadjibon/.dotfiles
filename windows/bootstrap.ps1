# Windows bootstrap: installs Git + PowerShell 7, clones the dotfiles, then runs setup.ps1.
#
#   irm https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/windows/bootstrap.ps1 | iex
#
# With options (extras, or a subset of steps):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/windows/bootstrap.ps1))) -Extras
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/windows/bootstrap.ps1))) -Only shell,neovim
[CmdletBinding()]
param(
    [switch]$Extras,
    [string[]]$Only,
    [string[]]$Skip
)

$ErrorActionPreference = 'Stop'
$Repo = 'https://github.com/amjadjibon/.dotfiles.git'
$Dir = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else { Join-Path $HOME '.dotfiles' }

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Green }

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store, then re-run.'
}

foreach ($pkg in @(
        @{ Id = 'Git.Git'; Cmd = 'git' },
        @{ Id = 'Microsoft.PowerShell'; Cmd = 'pwsh' })) {
    if (-not (Get-Command $pkg.Cmd -ErrorAction SilentlyContinue)) {
        Write-Step "Installing $($pkg.Id)"
        winget install --id $pkg.Id -e --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
        Update-SessionPath
    }
}

if (Test-Path (Join-Path $Dir '.git')) {
    Write-Step "Dotfiles already cloned, pulling latest ($Dir)"
    git -C $Dir pull --ff-only
} else {
    Write-Step "Cloning dotfiles to $Dir"
    git clone $Repo $Dir
}

# setup.ps1 needs PowerShell 7; this script may be running under Windows PowerShell 5.1.
$setupArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Dir 'windows\setup.ps1'))
if ($Extras) { $setupArgs += '-Extras' }
if ($Only) { $setupArgs += '-Only'; $setupArgs += ($Only -join ',') }
if ($Skip) { $setupArgs += '-Skip'; $setupArgs += ($Skip -join ',') }

Write-Step 'Running windows/setup.ps1'
& pwsh @setupArgs
exit $LASTEXITCODE
