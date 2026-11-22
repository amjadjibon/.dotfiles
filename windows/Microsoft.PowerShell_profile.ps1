# PowerShell 7 profile: the Windows counterpart of zsh/.zshrc.
# Linked to Documents\PowerShell\Microsoft.PowerShell_profile.ps1 by windows/setup.ps1.

# This file is symlinked into Documents\PowerShell; follow the link back to the repo.
$Dotfiles = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else {
    $self = Get-Item $PSCommandPath -ErrorAction SilentlyContinue
    if ($self.Target) { Split-Path (Split-Path ([string]$self.Target)) } else { Join-Path $HOME '.dotfiles' }
}
function Test-Command([string]$Name) { [bool](Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue) }

# ── Environment ──────────────────────────────────────────────────────────────
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'
foreach ($p in "$HOME\.local\bin", "$HOME\go\bin", "$HOME\.cargo\bin") {
    if ((Test-Path $p) -and ($env:Path -notlike "*$p*")) { $env:Path = "$p;$env:Path" }
}

# ── PSReadLine: zsh-autosuggestions + syntax highlighting ────────────────────
if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs
    # Predictions throw when output isn't a real console (redirected, CI, scripts)
    if (-not [Console]::IsOutputRedirected) {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle InlineView
    }
    Set-PSReadLineOption -HistoryNoDuplicates -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Ctrl+f -Function AcceptSuggestion          # like zsh-autosuggestions
    Set-PSReadLineKeyHandler -Key Alt+f -Function AcceptNextSuggestionWord
}

# ── Tool inits (only when installed) ─────────────────────────────────────────
if (Test-Command fzf) {
    if (Get-Module -ListAvailable PSFzf) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}
if (Get-Module -ListAvailable Terminal-Icons) { Import-Module Terminal-Icons }
if (Test-Command zoxide) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }
if (Test-Command fnm) { fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression }
if (Test-Command direnv) {
    # direnv looks for $HOME/XDG dirs, which Windows doesn't set. Don't set XDG_CONFIG_HOME:
    # that would also move Neovim's config away from %LOCALAPPDATA%\nvim.
    if (-not $env:DIRENV_CONFIG) { $env:DIRENV_CONFIG = Join-Path $HOME '.config\direnv' }
    New-Item -ItemType Directory -Force $env:DIRENV_CONFIG | Out-Null
    $hook = direnv hook pwsh 2>$null | Out-String
    if ($hook.Trim()) { Invoke-Expression $hook }
}
if (Test-Command uv) { (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression }
if (Test-Command gh) { gh completion -s powershell | Out-String | Invoke-Expression }

# ── Modern replacements (only when installed) ────────────────────────────────
# PowerShell ships aliases with some of these names; remove them so the functions win.
function Set-Replacement([string]$Name, [scriptblock]$Body) {
    Remove-Alias $Name -Force -ErrorAction SilentlyContinue
    Set-Item "Function:Global:$Name" $Body
}
if (Test-Command bat)   { Set-Replacement cat  { bat --paging=never @args } }
if (Test-Command eza) {
    Set-Replacement ls { eza --icons @args }
    Set-Replacement ll { eza -la --icons --git @args }
    Set-Replacement lt { eza --tree --icons --level=2 @args }
}
if (Test-Command dust)  { Set-Replacement du   { dust @args } }
if (Test-Command duf)   { Set-Replacement df   { duf @args } }
if (Test-Command procs) { Set-Replacement ps   { procs @args } }
if (Test-Command gping) { Set-Replacement ping { gping @args } }
if (Test-Command rg)    { Set-Replacement grep { rg @args } }
if (Test-Command fd)    { Set-Replacement find { fd @args } }
if (Test-Command sd)    { Set-Replacement sed  { sd @args } }
if (Test-Command xh)    { Set-Replacement curl { xh @args } }
if (Test-Command btm)   { Set-Replacement top  { btm @args } }
if (Test-Command nvim)  { Set-Alias vim nvim; Set-Alias vi nvim }

# ── Common commands ──────────────────────────────────────────────────────────
function q { exit }
Set-Alias c Clear-Host
function cs { Clear-Host; ls @args }
function pd { (Get-Location).Path }
function lsa { Get-ChildItem -Force @args }
function t {
    # time a command, like zsh's `time`: t go build ./...
    $sw = [Diagnostics.Stopwatch]::StartNew()
    & $args[0] @($args | Select-Object -Skip 1)
    Write-Host "`n$($sw.Elapsed)" -ForegroundColor DarkGray
}

# ── Directories ──────────────────────────────────────────────────────────────
function home { Set-Location $HOME }
function root { Set-Location '\' }
function desktop { Set-Location ([Environment]::GetFolderPath('Desktop')) }
Set-Alias o Invoke-Item
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ..... { Set-Location ..\..\..\.. }
function godir { Set-Location "$HOME\go\src" }

# ── Git (same names as .zshrc; overrides PowerShell's gc/gcm/gl aliases) ────
Set-Alias g git
Set-Replacement gs   { git status @args }
Set-Replacement gc   { git commit @args }
Set-Replacement gcm  { git commit -m @args }
Set-Replacement gcl  { git clone @args }
Set-Replacement gst  { git stash @args }
Set-Replacement gl   { git log @args }
Set-Replacement ga   { git add @args }
Set-Replacement gau  { git add -u @args }
Set-Replacement gall { git add . @args }
Set-Replacement gcam { git commit -am @args }
function git-ignore { git update-index --assume-unchanged @args }
function git-unignore { git update-index --no-assume-unchanged @args }
if (Test-Command lazygit) { Set-Alias lg lazygit }

# ── Python ───────────────────────────────────────────────────────────────────
function activate { & .\.venv\Scripts\Activate.ps1 }

# ── Profile shortcuts ────────────────────────────────────────────────────────
function profile { nvim $PROFILE }
function loadprofile { . $PROFILE }

# ── Prompt: Oh My Posh (keep last) ───────────────────────────────────────────
if (Test-Command oh-my-posh) {
    $theme = Join-Path $Dotfiles 'windows\ohmyposh\theme.omp.json'
    if (-not (Test-Path $theme)) { $theme = 'powerlevel10k_rainbow' }
    oh-my-posh init pwsh --config $theme | Invoke-Expression
}
