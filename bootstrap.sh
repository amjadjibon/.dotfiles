#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="https://github.com/amjadjibon/.dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SKIP_CLONE="${SKIP_CLONE:-false}"

# ── Colors ────────────────────────────────────────────────────────────────────
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
die() { red "ERROR: $*"; exit 1; }

green "==> Bootstrapping dotfiles on $(uname -s) $(uname -m)"

# ── Detect OS ─────────────────────────────────────────────────────────────────
if [[ "$(uname -s)" == "Darwin" ]]; then
  OS=macos
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  case "$ID_LIKE $ID" in
    *debian*|*ubuntu*) OS=debian ;;
    *rhel*|*fedora*)   OS=redhat ;;
    *arch*)            OS=arch ;;
    *) die "Unsupported Linux distribution: $ID" ;;
  esac
else
  die "Cannot detect OS"
fi
green "==> Detected OS: $OS"

# ── macOS: Xcode CLI tools + Homebrew ─────────────────────────────────────────
if [[ "$OS" == "macos" ]]; then
  if ! xcode-select -p &>/dev/null; then
    yellow "==> Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Re-run this script after the Xcode tools install completes."
    exit 0
  fi

  if ! command -v brew &>/dev/null; then
    yellow "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# ── Python 3 ──────────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  yellow "==> Installing Python 3..."
  case "$OS" in
    debian) sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip ;;
    redhat) sudo dnf install -y python3 python3-pip ;;
    arch)   sudo pacman -Sy --noconfirm python python-pip ;;
    macos)  brew install python3 ;;
  esac
fi

# ── pip / pipx / ansible ──────────────────────────────────────────────────────
if ! command -v ansible-playbook &>/dev/null; then
  yellow "==> Installing Ansible..."
  if command -v pipx &>/dev/null; then
    pipx install ansible
  else
    python3 -m pip install --user ansible
  fi
  # Ensure pip-installed scripts are on PATH
  export PATH="$HOME/.local/bin:$PATH"
fi

command -v ansible-playbook &>/dev/null || die "ansible-playbook not found after install"
green "==> Ansible $(ansible --version | head -1)"

# ── Git ───────────────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  yellow "==> Installing git..."
  case "$OS" in
    debian) sudo apt-get update -qq && sudo apt-get install -y git ;;
    redhat) sudo dnf install -y git ;;
    arch)   sudo pacman -Sy --noconfirm git ;;
    macos)  brew install git ;;
  esac
fi

# ── Clone dotfiles ─────────────────────────────────────────────────────────────
if [[ "$SKIP_CLONE" == "true" ]]; then
  green "==> Skipping clone, using: $DOTFILES_DIR"
elif [[ ! -d "$DOTFILES_DIR" ]]; then
  yellow "==> Cloning dotfiles to $DOTFILES_DIR..."
  git clone --recurse-submodules "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  yellow "==> Dotfiles already cloned, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only
  git -C "$DOTFILES_DIR" submodule update --init --recursive
fi

cd "$DOTFILES_DIR"

# ── Ansible Galaxy collections ────────────────────────────────────────────────
yellow "==> Installing Ansible Galaxy requirements..."
ansible-galaxy collection install -r ansible/requirements.yml

# ── Parse args ────────────────────────────────────────────────────────────────
EXTRAS_VAR=""
PASS_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--extras" ]]; then
    EXTRAS_VAR="-e install_extras=true"
  else
    PASS_ARGS+=("$arg")
  fi
done

# ── Run playbook ──────────────────────────────────────────────────────────────
yellow "==> Running setup playbook (this will take a while)..."
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/setup.yml \
  -e ansible_python_interpreter=/usr/bin/python3 \
  $EXTRAS_VAR \
  "${PASS_ARGS[@]}"

green ""
green "==> Done! Restart your shell or run: source ~/.zshrc"
