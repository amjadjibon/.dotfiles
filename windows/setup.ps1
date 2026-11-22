#Requires -Version 7.0
# Windows counterpart of ansible/setup.yml. Idempotent: safe to re-run.
#
#   pwsh windows/setup.ps1                      # everything except extras
#   pwsh windows/setup.ps1 -Extras              # + modern Unix tools
#   pwsh windows/setup.ps1 -Only shell,neovim   # selected steps
#   pwsh windows/setup.ps1 -Skip rust           # everything but rust
#   pwsh windows/setup.ps1 -Headless            # CI: skip the interactive NvChad bootstrap
#
# Steps: packages dotfiles shell fonts terminal neovim go python rust node jj devtools aicli extras
#
# Not installed on Windows on purpose (use them from WSL): docker, kubernetes, terraform, awscli, tmux.
[CmdletBinding()]
param(
    [switch]$Extras,
    [switch]$Headless,
    [string[]]$Only,
    [string[]]$Skip
)

$ErrorActionPreference = 'Stop'
$Dotfiles = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$WinDir = Join-Path $Dotfiles 'windows'

# -File passes "a,b" as one string; accept both forms.
$Only = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Skip = @($Skip | ForEach-Object { $_ -split ',' } | Where-Object { $_ })

$Failed = [System.Collections.Generic.List[string]]::new()

# ── Helpers ──────────────────────────────────────────────────────────────────
function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Green }
function Write-Info($msg) { Write-Host "    $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "    ! $msg" -ForegroundColor Yellow }

function Test-Step([string]$Name) {
    if ($Only.Count -gt 0) { return $Only -contains $Name }
    if ($Skip -contains $Name) { return $false }
    if ($Name -eq 'extras') { return [bool]$Extras }
    return $true
}

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Install-WingetPackage {
    param([Parameter(Mandatory)][string]$Id, [string[]]$ExtraArgs = @())
    winget list --id $Id -e --source winget --disable-interactivity *> $null
    if ($LASTEXITCODE -eq 0) { Write-Info "$Id (installed)"; return }
    Write-Info "$Id (installing)"
    winget install --id $Id -e --source winget --silent `
        --accept-package-agreements --accept-source-agreements --disable-interactivity @ExtraArgs
    # 0x8A15002B: already installed / no applicable upgrade
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        Write-Warn "winget exited with $LASTEXITCODE for $Id"
        $script:Failed.Add($Id)
    }
    Update-SessionPath
}

function New-Link {
    # Symlink $Path -> $Target. Backs up a real file/dir that is in the way.
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Target)
    $item = Get-Item $Path -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $Target) { Write-Info "$Path (linked)"; return }
        if ($item.LinkType) {
            Remove-Item $Path -Force
        } else {
            $backup = "$Path.bak-$(Get-Date -Format yyyyMMddHHmmss)"
            Move-Item $Path $backup
            Write-Warn "moved existing $Path -> $backup"
        }
    }
    New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null
    try {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target -ErrorAction Stop | Out-Null
    } catch {
        throw "Could not create symlink $Path. Turn on Developer Mode (Settings > System > For developers) or run this from an elevated terminal, then re-run."
    }
    Write-Info "$Path -> $Target"
}

# ── packages ─────────────────────────────────────────────────────────────────
if (Test-Step 'packages') {
    Write-Step 'Core packages'
    foreach ($id in @(
            'Git.Git', 'Microsoft.PowerShell', 'dandavison.delta', 'JesseDuffield.lazygit',
            'BurntSushi.ripgrep.MSVC', 'sharkdp.fd', 'junegunn.fzf', 'jqlang.jq', 'Fastfetch-cli.Fastfetch')) {
        Install-WingetPackage $id
    }
}

# ── dotfiles ─────────────────────────────────────────────────────────────────
if (Test-Step 'dotfiles') {
    Write-Step 'Dotfiles links'

    # PowerShell 7 profile (Documents may be redirected to OneDrive; GetFolderPath handles that)
    $docs = [Environment]::GetFolderPath('MyDocuments')
    New-Link -Path (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1') `
             -Target (Join-Path $WinDir 'Microsoft.PowerShell_profile.ps1')

    # Git: shared config + Windows overrides. A small wrapper, not a link, so the
    # overrides can come after the include.
    $gitconfig = Join-Path $HOME '.gitconfig'
    $repo = $Dotfiles -replace '\\', '/'
    $wrapper = @"
# Managed by .dotfiles/windows/setup.ps1
[include]
	path = $repo/git/.gitconfig

# Windows overrides (must come after the include)
[core]
	excludesfile = $repo/git/.gitignore
	autocrlf = true
"@
    if ((Test-Path $gitconfig) -and -not ((Get-Content $gitconfig -Raw) -match 'Managed by \.dotfiles')) {
        $backup = "$gitconfig.bak-$(Get-Date -Format yyyyMMddHHmmss)"
        Move-Item $gitconfig $backup
        Write-Warn "moved existing $gitconfig -> $backup"
    }
    Set-Content -Path $gitconfig -Value $wrapper -NoNewline
    Write-Info "$gitconfig (include wrapper)"
    if (-not (Test-Path (Join-Path $HOME '.gitconfig.local'))) {
        Write-Warn 'create ~/.gitconfig.local with your [user] name/email/signingkey (commits are signed)'
    }

    # SSH: Windows OpenSSH has no ControlMaster, so it gets its own config
    New-Link -Path (Join-Path $HOME '.ssh\config') -Target (Join-Path $WinDir 'ssh\config')

    # Neovim reads %LOCALAPPDATA%\nvim on Windows
    New-Link -Path (Join-Path $env:LOCALAPPDATA 'nvim') -Target (Join-Path $Dotfiles 'nvim')

    # jj reads %APPDATA%\jj\config.toml on Windows
    New-Link -Path (Join-Path $env:APPDATA 'jj\config.toml') -Target (Join-Path $Dotfiles 'jj\config.toml')
}

# ── shell: PowerShell + Oh My Posh ───────────────────────────────────────────
if (Test-Step 'shell') {
    Write-Step 'PowerShell + Oh My Posh'
    Install-WingetPackage 'JanDeDobbeleer.OhMyPosh'

    # Allow the (local, unsigned) profile to run
    if ((Get-ExecutionPolicy -Scope CurrentUser) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Info 'execution policy: RemoteSigned (CurrentUser)'
    }

    # PSReadLine (autosuggestions + highlighting), PSFzf (Ctrl+R/Ctrl+T), Terminal-Icons
    # PowerShell 7 bundles PSReadLine; predictions need >= 2.2.6.
    $minVersion = @{ 'PSReadLine' = [version]'2.2.6'; 'PSFzf' = [version]'0.0'; 'Terminal-Icons' = [version]'0.0' }
    foreach ($mod in $minVersion.Keys) {
        $have = Get-Module -ListAvailable -Name $mod | Where-Object { $_.Version -ge $minVersion[$mod] -and $_.ModuleBase -notlike '*\WindowsPowerShell\*' }
        if ($have) { Write-Info "$mod (installed)"; continue }
        Write-Info "$mod (installing)"
        # -Repository: without it PSResourceGet may query MicrosoftArtifactRegistry first and fail
        Install-PSResource -Name $mod -Repository PSGallery -Scope CurrentUser -TrustRepository -Quiet
    }
}

# ── fonts ────────────────────────────────────────────────────────────────────
if (Test-Step 'fonts') {
    Write-Step 'MesloLGS NF (Powerlevel10k / NvChad glyphs)'
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $fontReg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    New-Item -ItemType Directory -Force $fontDir | Out-Null
    foreach ($f in 'MesloLGS NF Regular.ttf', 'MesloLGS NF Bold.ttf', 'MesloLGS NF Italic.ttf', 'MesloLGS NF Bold Italic.ttf') {
        $dest = Join-Path $fontDir $f
        if (-not (Test-Path $dest)) {
            Invoke-WebRequest -Uri ('https://github.com/romkatv/powerlevel10k-media/raw/master/' + [uri]::EscapeDataString($f)) -OutFile $dest
        }
        New-ItemProperty -Path $fontReg -Name ($f -replace '\.ttf$', ' (TrueType)') -Value $dest -PropertyType String -Force | Out-Null
        Write-Info $f
    }
}

# ── terminal: Windows Terminal defaults ──────────────────────────────────────
if (Test-Step 'terminal') {
    Write-Step 'Windows Terminal'
    $wt = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -Filter 'Microsoft.WindowsTerminal_*' -ErrorAction SilentlyContinue |
          ForEach-Object { Join-Path $_.FullName 'LocalState\settings.json' } | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $wt) {
        Write-Warn 'Windows Terminal settings.json not found (open Windows Terminal once, then re-run -Only terminal)'
    } else {
        # Patch only what we own; Windows Terminal rewrites this file itself, so no symlink.
        $s = Get-Content $wt -Raw | ConvertFrom-Json -AsHashtable
        if (-not $s.profiles.defaults) { $s.profiles.defaults = @{} }
        $s.profiles.defaults.font = @{ face = 'MesloLGS NF' }
        $pwshProfile = $s.profiles.list | Where-Object { $_.source -eq 'Windows.Terminal.PowershellCore' } | Select-Object -First 1
        if ($pwshProfile) { $s.defaultProfile = $pwshProfile.guid }
        Copy-Item $wt "$wt.bak" -Force
        $s | ConvertTo-Json -Depth 32 | Set-Content $wt
        Write-Info 'font: MesloLGS NF, default profile: PowerShell 7'
    }
}

# ── neovim ───────────────────────────────────────────────────────────────────
if (Test-Step 'neovim') {
    Write-Step 'Neovim + NvChad'
    Install-WingetPackage 'Neovim.Neovim'
    if ($Headless) {
        Write-Info 'NvChad bootstrap skipped (-Headless)'
    } elseif (-not (Test-Path (Join-Path $env:LOCALAPPDATA 'nvim-data\lazy\NvChad'))) {
        Write-Info 'bootstrapping NvChad plugins (headless)'
        nvim --headless '+Lazy! sync' +qa
    } else { Write-Info 'NvChad plugins (installed)' }
}

# ── go ───────────────────────────────────────────────────────────────────────
if (Test-Step 'go') {
    Write-Step 'Go'
    Install-WingetPackage 'GoLang.Go'
    Install-WingetPackage 'GolangCI.golangci-lint'
    foreach ($pkg in 'golang.org/x/tools/gopls@latest', 'github.com/go-delve/delve/cmd/dlv@latest', 'mvdan.cc/gofumpt@latest') {
        $bin = ($pkg -split '/')[-1] -replace '@.*$', ''
        if (Test-Command $bin) { Write-Info "$bin (installed)"; continue }
        Write-Info "$bin (go install)"
        go install $pkg
    }
}

# ── python: uv ───────────────────────────────────────────────────────────────
if (Test-Step 'python') {
    Write-Step 'Python (uv)'
    Install-WingetPackage 'astral-sh.uv'
    uv python install --quiet
    foreach ($tool in 'ruff', 'ty', 'ipython', 'jupyterlab') {
        $bin = if ($tool -eq 'jupyterlab') { 'jupyter-lab' } else { $tool }
        if (Test-Command $bin) { Write-Info "$tool (installed)"; continue }
        Write-Info "$tool (uv tool install)"
        uv tool install --quiet $tool
    }
}

# ── rust ─────────────────────────────────────────────────────────────────────
if (Test-Step 'rust') {
    Write-Step 'Rust (rustup + MSVC build tools)'
    # The MSVC toolchain needs the VC++ build tools (asks for admin, several GB).
    # Skip if any Visual Studio install already has them (e.g. GitHub's Windows runners).
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $hasVC = (Test-Path $vswhere) -and
             (& $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
    if ($hasVC) {
        Write-Info 'MSVC build tools (installed)'
    } else {
        Install-WingetPackage 'Microsoft.VisualStudio.2022.BuildTools' -ExtraArgs @(
            '--override', '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended')
    }
    Install-WingetPackage 'Rustlang.Rustup'
    $env:Path = "$HOME\.cargo\bin;$env:Path"
    rustup default stable
    rustup component add clippy rustfmt rust-analyzer
}

# ── node: fnm (Windows stand-in for nvm) ─────────────────────────────────────
if (Test-Step 'node') {
    Write-Step 'Node (fnm + LTS)'
    Install-WingetPackage 'Schniz.fnm'
    fnm env --shell powershell | Out-String | Invoke-Expression
    fnm install --lts
    fnm default lts-latest
    fnm use lts-latest
    foreach ($pkg in 'typescript', 'ts-node', 'prettier', 'eslint') {
        npm ls -g $pkg --depth=0 *> $null
        if ($LASTEXITCODE -eq 0) { Write-Info "$pkg (installed)"; continue }
        Write-Info "$pkg (npm -g)"
        npm install -g $pkg --silent
    }
}

# ── jj ───────────────────────────────────────────────────────────────────────
if (Test-Step 'jj') {
    Write-Step 'Jujutsu (jj)'
    Install-WingetPackage 'jj-vcs.jj'
}

# ── devtools ─────────────────────────────────────────────────────────────────
if (Test-Step 'devtools') {
    Write-Step 'Dev tools (direnv, gh, mkcert, age, sops)'
    foreach ($id in 'direnv.direnv', 'GitHub.cli', 'FiloSottile.mkcert', 'FiloSottile.age', 'SecretsOPerationS.SOPS') {
        Install-WingetPackage $id
    }
}

# ── aicli: install methods from each vendor's docs ───────────────────────────
if (Test-Step 'aicli') {
    Write-Step 'AI CLI tools (claude, codex, opencode)'

    # Claude Code, native installer: https://code.claude.com/docs/en/setup
    if (Test-Command 'claude') { Write-Info 'claude (installed)' }
    else { Write-Info 'claude (installer)'; Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression }

    # Codex, standalone installer: https://github.com/openai/codex
    if (Test-Command 'codex') { Write-Info 'codex (installed)' }
    else { Write-Info 'codex (installer)'; Invoke-RestMethod https://chatgpt.com/codex/install.ps1 | Invoke-Expression }

    # opencode: no Windows package-manager support per https://opencode.ai/docs, so npm.
    # Earlier steps reset PATH from the registry, which drops fnm's node; restore it.
    if (Test-Command 'fnm') { fnm env --shell powershell | Out-String | Invoke-Expression }
    if (Test-Command 'opencode') { Write-Info 'opencode (installed)' }
    elseif (Test-Command 'npm') { Write-Info 'opencode (npm -g)'; npm install -g @opencode/cli --silent }
    else { Write-Warn 'opencode needs npm; run the node step first' }
    Update-SessionPath
}

# ── extras (opt-in) ──────────────────────────────────────────────────────────
if (Test-Step 'extras') {
    Write-Step 'Extras (modern Unix tools)'
    foreach ($id in @(
            'ajeetdsouza.zoxide', 'sharkdp.bat', 'eza-community.eza', 'bootandy.dust', 'muesli.duf',
            'Clement.bottom', 'ducaale.xh', 'sharkdp.hyperfine', 'Casey.Just', 'koalaman.shellcheck',
            'MikeFarah.yq', 'orf.gping', 'dalance.procs', 'chmln.sd', 'tldr-pages.tlrc')) {
        Install-WingetPackage $id
    }
}

if ($Failed.Count) {
    Write-Host "`n==> Finished with $($Failed.Count) failed package(s): $($Failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "`n==> Done. Open a new PowerShell 7 tab (or run: . `$PROFILE)" -ForegroundColor Green
