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
