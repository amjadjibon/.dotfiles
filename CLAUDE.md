# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a personal dotfiles repository managed manually (no stow or install script). Configs are symlinked or copied to their destinations by hand.

| File | Symlink/copy destination |
|------|--------------------------|
| `zsh/.zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `jj/config.toml` | `~/.config/jj/config.toml` |
| `git/.gitignore` | `~/.gitignore` |
| `ssh/config` | `~/.ssh/config` |

## Shell (`zsh/.zshrc`)

- Uses **oh-my-zsh** (`~/.oh-my-zsh`) with the **Powerlevel10k** theme.
- Active plugins: `git`, `zsh-autosuggestions`.
- External syntax highlighting sourced from `~/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`.
- Conda (miniforge3) is initialised via the block near the bottom — keep that block intact.
- `vim` is aliased to `lvim` (LunarVim).
- `python`/`pip` are aliased to `python3`/`pip3`.
- PATH additions (in order): Flutter, pub-cache, `~/.local/bin`, Homebrew (`/opt/homebrew/bin`), wasmtime.

## Tmux (`tmux/tmux.conf`)

- Plugin manager: **TPM** (`~/.tmux/plugins/tpm/tpm`). After editing plugins, reload with `prefix + I` inside tmux.
- Prefix rebound to `C-a`.
- Vi mode enabled (`mode-keys vi`).
- Pane navigation via `h/j/k/l` (vim-tmux-navigator).
- Split bindings: `-` for horizontal split, `_` for vertical split.
- Theme: **catppuccin/tmux**.

## Jujutsu VCS (`jj/config.toml`)

- User identity: Amjad Hossain / amjad.jibon@gmail.com
- Default command: `jj log`
- Aliases: `l` (recent log), `ll` (full log), `s` (status), `d` (diff)
- Auto-creates local bookmarks when fetching from git remotes.

## Ansible Playbook

Cross-platform playbook supporting macOS, Ubuntu/Debian, Fedora/RHEL, Arch Linux, and Docker.

| Tag | What it installs |
|-----|-----------------|
| `packages` | Homebrew (macOS) or apt/dnf/pacman core tools |
| `zsh` | zsh, Oh My Zsh, Powerlevel10k, autosuggestions |
| `tmux` | tmux + TPM |
| `fonts` | MesloLGS NF (Powerlevel10k's patched font, required by NvChad + Powerlevel10k) |
| `neovim` | Neovim (GitHub release on Ubuntu) + NvChad |
| `go` | Go (brew/pkg manager; golang.org binary on Ubuntu) |
| `python` | Miniforge (conda) |
| `rust` | rustup + clippy, rustfmt, rust-analyzer |
| `node` | NVM + Node LTS |
| `dotfiles` | Symlinks `zsh/.zshrc`, `tmux/tmux.conf`, and `jj/config.toml` |
| `jj` | Jujutsu VCS (brew on macOS, GitHub release on Linux, `jujutsu` on Arch) |
| `kubernetes` | kubectl + helm + k9s |
| `devtools` | direnv, gh, mkcert, age, sops |
| `extras` | Modern Unix (eza, bat, fd, ripgrep, fzf, delta, jq, yq, zoxide, …) + dev tools (just, shellcheck, act, grpcurl, websocat, pre-commit) + k8s extras (kubectx, kubens, kind, lazydocker, dive) + cloud CLIs (gcloud, azure-cli, vault) |

```sh
# First-time setup (via bootstrap script)
curl -fsSL https://raw.githubusercontent.com/amjadjibon/.dotfiles/main/bootstrap.sh | bash

# With extras
bash bootstrap.sh --extras

# Manual setup
pip3 install ansible
ansible-galaxy collection install -r ansible/requirements.yml

# Run everything
ansible-playbook -i ansible/inventory.ini ansible/setup.yml

# Run everything including extras
ansible-playbook -i ansible/inventory.ini ansible/setup.yml -e install_extras=true

# Run a single component
ansible-playbook -i ansible/inventory.ini ansible/setup.yml --tags neovim

# Run only extras
ansible-playbook -i ansible/inventory.ini ansible/setup.yml --tags extras -e install_extras=true
```

## Docker Tests

Test the playbook against Ubuntu, Fedora, and Arch Linux containers.
Two tasks are skipped in Docker via `headless=true`: setting the default shell (requires PAM) and NvChad headless bootstrap (requires TTY).

```sh
make test           # run all three
make test-ubuntu
make test-fedora
make test-arch
make clean          # remove images and containers
```

## Applying Changes

After editing `zsh/.zshrc`, reload with:
```sh
source ~/.zshrc
```

After editing `tmux/tmux.conf`, reload with:
```sh
tmux source ~/.tmux.conf
```
