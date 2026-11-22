# .dotfiles

Personal development environment managed with Ansible. Supports macOS, Ubuntu/Debian, Fedora/RHEL, Arch Linux, and Docker containers.

## Quick Start

```sh
curl -fsSL https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/bootstrap.sh | bash
```

With optional extras (modern Unix tools, cloud CLIs, k8s tools, etc.):

```sh
curl -fsSL https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/bootstrap.sh | bash -s -- --extras
```

### Windows

PowerShell 7 + Oh My Posh instead of zsh + Oh My Zsh, installed with winget. Run from any PowerShell window:

```powershell
irm https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/windows/bootstrap.ps1 | iex
```

With extras, or only some steps:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/windows/bootstrap.ps1))) -Extras
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/windows/bootstrap.ps1))) -Only shell,neovim
```

Needs **Developer Mode** (Settings → System → For developers) so configs can be symlinked without admin. See [Windows](#windows-1) below.

## What Gets Installed

| Tag | What it installs |
|-----|-----------------|
| `packages` | Core system packages (curl, git, build-essential, etc.) |
| `dotfiles` | Symlinks: `.zshrc`, `tmux.conf`, `.gitconfig`, `.gitignore`, `ssh/config`, `jj/config.toml` |
| `zsh` | zsh + Oh My Zsh + Powerlevel10k + autosuggestions + syntax highlighting |
| `tmux` | tmux + TPM + plugins (sensible, vim-tmux-navigator, catppuccin) |
| `fonts` | MesloLGS NF (required by Powerlevel10k and NvChad) |
| `neovim` | Neovim + NvChad |
| `go` | Go + gopls, delve, golangci-lint, gofumpt |
| `python` | uv + Python + ruff, ty, ipython, jupyterlab |
| `rust` | rustup + clippy, rustfmt, rust-analyzer |
| `node` | NVM + Node LTS + typescript, ts-node, prettier, eslint |
| `jj` | Jujutsu VCS |
| `awscli` | AWS CLI v2 |
| `terraform` | Terraform (HashiCorp) |
| `docker` | Docker Engine + Compose plugin |
| `kubernetes` | kubectl + helm + k9s |
| `devtools` | direnv, gh, mkcert, age, sops |
| `aicli` | claude-code, codex, opencode |
| `extras` | Modern Unix tools, shell utilities, k8s extras, cloud CLIs, dev workflow tools *(opt-in)* |

### Extras detail

Enabled with `--extras` or `-e install_extras=true`:

| Category | Tools |
|----------|-------|
| Shell / search | fzf, ripgrep, fd, bat, git-delta, jq, yq, shellcheck |
| Modern Unix | eza, lsd, dust, duf, broot, mcfly, bottom, zoxide, xh, procs, gping, hyperfine, sd, choose, tldr, glances, httpie, curlie, doggo, cheat |
| Dev workflow | just, act, pre-commit |
| API / network | grpcurl, websocat |
| K8s / containers | kubectx, kubens, kind, lazydocker, dive |
| Cloud CLIs | gcloud, azure-cli, vault |

## Dotfiles

| File | Destination |
|------|-------------|
| `zsh/.zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `git/.gitconfig` | `~/.gitconfig` |
| `git/.gitignore` | `~/.gitignore` |
| `ssh/config` | `~/.ssh/config` |
| `jj/config.toml` | `~/.config/jj/config.toml` |

## Manual Usage

```sh
# Install Ansible
pip3 install ansible
ansible-galaxy collection install -r ansible/requirements.yml

# Run everything
ansible-playbook -i ansible/inventory.ini ansible/setup.yml

# Run everything + extras
ansible-playbook -i ansible/inventory.ini ansible/setup.yml -e install_extras=true

# Run a single tag
ansible-playbook -i ansible/inventory.ini ansible/setup.yml --tags neovim

# Run only extras on an existing machine
ansible-playbook -i ansible/inventory.ini ansible/setup.yml --tags extras -e install_extras=true
```

## Windows

`windows/setup.ps1` mirrors the Ansible tags. It is idempotent; re-run it any time.

```powershell
pwsh windows/setup.ps1                     # everything except extras
pwsh windows/setup.ps1 -Extras             # + modern Unix tools
pwsh windows/setup.ps1 -Only shell,neovim  # selected steps
pwsh windows/setup.ps1 -Skip rust          # everything but rust
pwsh windows/setup.ps1 -Headless           # CI: skip the NvChad bootstrap
pwsh windows/verify.ps1                    # check tools, links, git config and that the profile loads
```

CI runs `setup.ps1 -Headless` + `verify.ps1` on `windows-latest` (see `.github/workflows/test.yml`).

| Step | What it does on Windows |
|------|-------------------------|
| `packages` | Git, PowerShell 7, delta, lazygit, ripgrep, fd, fzf, jq, fastfetch |
| `dotfiles` | Symlinks the PowerShell profile, `nvim/`, `jj/config.toml`, `windows/ssh/config`; writes a `~/.gitconfig` that includes `git/.gitconfig` |
| `shell` | Oh My Posh + PSReadLine (autosuggestions, highlighting), PSFzf, Terminal-Icons |
| `fonts` | MesloLGS NF (per-user) |
| `terminal` | Windows Terminal: MesloLGS NF font, PowerShell 7 as default profile |
| `neovim` | Neovim + NvChad |
| `go` | Go + golangci-lint, gopls, delve, gofumpt |
| `python` | uv + Python + ruff, ty, ipython, jupyterlab |
| `rust` | VS C++ Build Tools (needed by the MSVC toolchain) + rustup, clippy, rustfmt, rust-analyzer |
| `node` | fnm (stand-in for NVM) + Node LTS + typescript, ts-node, prettier, eslint |
| `jj` | Jujutsu |
| `devtools` | direnv, gh, mkcert, age, sops |
| `aicli` | Claude Code and Codex (official `install.ps1` installers), opencode (npm) |
| `extras` | zoxide, bat, eza, dust, duf, bottom, xh, hyperfine, just, shellcheck, yq, gping, procs, sd, tldr *(opt-in)* |

Not installed on Windows on purpose: docker, kubernetes, terraform, awscli, tmux. Use them from WSL.

| File | Windows destination |
|------|---------------------|
| `windows/Microsoft.PowerShell_profile.ps1` | `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| `windows/ohmyposh/theme.omp.json` | read by the profile (Powerlevel10k-style theme) |
| `windows/ssh/config` | `~\.ssh\config` (no ControlMaster: unsupported by Windows OpenSSH) |
| `nvim/` | `%LOCALAPPDATA%\nvim` |
| `jj/config.toml` | `%APPDATA%\jj\config.toml` |
| `git/.gitconfig` | included from `~\.gitconfig` (adds `autocrlf = true`) |

## Docker Tests

Tests the playbook against Ubuntu, Fedora, and Arch Linux containers. Two tasks are skipped in containers via `headless=true`: setting the default shell (requires PAM) and NvChad bootstrap (requires TTY).

```sh
make test           # run all three
make test-ubuntu
make test-fedora
make test-arch
make clean
```

## Reload Configs

```sh
source ~/.zshrc          # after editing zsh/.zshrc
tmux source ~/.tmux.conf # after editing tmux/tmux.conf
```
