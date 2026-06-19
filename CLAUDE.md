# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a personal dotfiles repository managed manually (no stow or install script). Configs are symlinked or copied to their destinations by hand.

| File | Symlink/copy destination |
|------|--------------------------|
| `zsh/.zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |

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

## Ansible Playbook

Cross-platform playbook supporting macOS, Ubuntu/Debian, Fedora/RHEL, Arch Linux, and Docker.

| Tag | What it installs |
|-----|-----------------|
| `packages` | Homebrew (macOS) or apt/dnf/pacman core tools |
| `zsh` | zsh, Oh My Zsh, Powerlevel10k, autosuggestions |
| `tmux` | tmux + TPM |
| `neovim` | Neovim (GitHub release on Ubuntu) + NvChad |
| `go` | Go (brew/pkg manager; golang.org binary on Ubuntu) |
| `python` | Miniforge (conda) |
| `rust` | rustup + clippy, rustfmt, rust-analyzer |
| `node` | NVM + Node LTS |
| `dotfiles` | Symlinks `zsh/.zshrc` and `tmux/tmux.conf` |

```sh
# First-time setup
pip3 install ansible
ansible-galaxy collection install -r ansible/requirements.yml

# Run everything
ansible-playbook -i ansible/inventory.ini ansible/setup.yml

# Run a single component
ansible-playbook -i ansible/inventory.ini ansible/setup.yml --tags neovim
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
