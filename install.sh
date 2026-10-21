#!/usr/bin/env bash
#
# Installs the tools used by these dotfiles: lazygit, starship, oh-my-zsh, claude.
# Supports macOS (Homebrew) and Arch-based Linux (pacman / AUR helper).
# Safe to re-run: already installed tools are skipped.

set -euo pipefail

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m  ✗\033[0m %s\n' "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
AUR_HELPER=""

# --- package manager helpers -------------------------------------------------

setup_macos() {
  if ! has brew; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  ok "Homebrew ready"
}

setup_linux() {
  has pacman || die "Only Arch-based distributions (pacman) are supported on Linux"
  for helper in paru yay; do
    if has "$helper"; then
      AUR_HELPER="$helper"
      break
    fi
  done
  info "Syncing pacman database"
  sudo pacman -Sy --noconfirm
}

pkg_install() {
  case "$OS" in
    Darwin) brew install "$@" ;;
    Linux)  sudo pacman -S --needed --noconfirm "$@" ;;
  esac
}

# --- tools -------------------------------------------------------------------

install_base() {
  local missing=()
  for cmd in git curl zsh; do
    has "$cmd" || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    info "Installing base tools: ${missing[*]}"
    pkg_install "${missing[@]}"
  fi
  ok "git, curl, zsh"
}

install_lazygit() {
  if has lazygit; then
    ok "lazygit already installed"
    return
  fi
  info "Installing lazygit"
  pkg_install lazygit
  ok "lazygit"
}

install_starship() {
  if has starship; then
    ok "starship already installed"
    return
  fi
  info "Installing starship"
  pkg_install starship
  ok "starship"
}

install_oh_my_zsh() {
  # .zshrc expects ~/.oh-my-zsh on macOS and /usr/share/oh-my-zsh on Linux
  if [[ "$OS" == "Linux" ]]; then
    if [[ -d /usr/share/oh-my-zsh ]]; then
      ok "oh-my-zsh already installed"
      return
    fi
    info "Installing oh-my-zsh"
    if [[ -n "$AUR_HELPER" ]]; then
      "$AUR_HELPER" -S --needed --noconfirm oh-my-zsh-git
    else
      warn "No AUR helper found, cloning oh-my-zsh into /usr/share/oh-my-zsh"
      sudo git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh
    fi
  else
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
      ok "oh-my-zsh already installed"
      return
    fi
    info "Installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi
  ok "oh-my-zsh"
}

install_claude() {
  if has claude; then
    ok "claude already installed"
    return
  fi
  info "Installing claude"
  curl -fsSL https://claude.ai/install.sh | bash
  ok "claude"
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    return
  fi
  info "Setting zsh as the default shell"
  grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$zsh_path" || warn "Could not change the default shell, run: chsh -s $zsh_path"
}

# --- main --------------------------------------------------------------------

main() {
  case "$OS" in
    Darwin) setup_macos ;;
    Linux)  setup_linux ;;
    *)      die "Unsupported OS: $OS" ;;
  esac

  install_base
  install_lazygit
  install_starship
  install_oh_my_zsh
  install_claude
  set_default_shell

  info "Done. Open a new terminal to pick up the changes."
}

main "$@"
