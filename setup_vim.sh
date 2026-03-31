#!/usr/bin/env bash
# =============================================================================
#  setup_vim.sh — Bootstraps Sim's Vim environment on a fresh macOS / Linux box
# =============================================================================
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[✔]${NC} $*"; }
info() { echo -e "${CYAN}[→]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[✘]${NC} $*" >&2; exit 1; }

# ── OS detection ─────────────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)
      if   command -v apt-get &>/dev/null; then OS="debian"
      elif command -v dnf     &>/dev/null; then OS="fedora"
      elif command -v pacman  &>/dev/null; then OS="arch"
      else die "Unsupported Linux distro (no apt/dnf/pacman found)."
      fi
      ;;
    *) die "Unsupported OS: $(uname -s)" ;;
  esac
  ok "OS detected: $OS"
}

# ── Package installer helpers ─────────────────────────────────────────────────
install_pkg() {
  local pkg=$1
  case "$OS" in
    macos)  brew install "$pkg" ;;
    debian) sudo apt-get install -y "$pkg" ;;
    fedora) sudo dnf install -y "$pkg" ;;
    arch)   sudo pacman -S --noconfirm "$pkg" ;;
  esac
}

ensure_pkg() {
  local cmd=$1 pkg=${2:-$1}
  if command -v "$cmd" &>/dev/null; then
    ok "$cmd already installed"
  else
    info "Installing $pkg …"
    install_pkg "$pkg"
    ok "$pkg installed"
  fi
}

# ── Homebrew (macOS only) ─────────────────────────────────────────────────────
install_homebrew() {
  if [[ "$OS" != "macos" ]]; then return; fi
  if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
  else
    info "Installing Homebrew …"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
    ok "Homebrew installed"
  fi
}

# ── apt update (Debian/Ubuntu only) ──────────────────────────────────────────
refresh_pkg_cache() {
  if [[ "$OS" == "debian" ]]; then
    info "Updating apt cache …"
    sudo apt-get update -qq
  fi
}

# ── Core dependencies ─────────────────────────────────────────────────────────
install_dependencies() {
  info "Checking core dependencies …"
  ensure_pkg vim
  ensure_pkg git
  ensure_pkg curl
}

# ── Vundle ────────────────────────────────────────────────────────────────────
install_vundle() {
  local vundle_dir="$HOME/.vim/bundle/Vundle.vim"
  if [[ -d "$vundle_dir/.git" ]]; then
    ok "Vundle already installed — pulling latest …"
    git -C "$vundle_dir" pull --quiet
  else
    info "Cloning Vundle …"
    git clone --quiet https://github.com/VundleVim/Vundle.vim.git "$vundle_dir"
    ok "Vundle cloned"
  fi
}

# ── .vimrc ────────────────────────────────────────────────────────────────────
VIMRC_URL="https://raw.githubusercontent.com/SimonIsCoding/.vimrc/main/.vimrc"

write_vimrc() {
  local vimrc="$HOME/.vimrc"
  if [[ -f "$vimrc" ]]; then
    warn ".vimrc already exists — backing up to ~/.vimrc.bak"
    cp "$vimrc" "$HOME/.vimrc.bak"
  fi
  info "Downloading .vimrc from GitHub …"
  curl -fsSL "$VIMRC_URL" -o "$vimrc" \
    || die "Failed to download .vimrc from $VIMRC_URL"
  ok ".vimrc downloaded"
}

# ── Plugin installation ───────────────────────────────────────────────────────
install_plugins() {
  info "Installing Vim plugins via Vundle (this may take a moment) …"
  vim +PluginInstall +qall 2>/dev/null || true
  ok "Plugins installed"
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   Vim environment ready to go  🎉        ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${CYAN}~/.vimrc${NC}              written"
  echo -e "  ${CYAN}~/.vim/bundle/${NC}        Vundle + plugins"
  echo -e "  ${CYAN}colorscheme${NC}           everforest (dark/hard)"
  echo -e "  ${CYAN}airline theme${NC}         everforest"
  echo ""
  echo -e "  Open Vim and run ${YELLOW}:PluginInstall${NC} if anything looks off."
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}"
  echo "  ╔═══════════════════════════════════╗"
  echo "  ║       Sim's Vim Setup Script      ║"
  echo "  ╚═══════════════════════════════════╝"
  echo -e "${NC}"

  detect_os
  install_homebrew
  refresh_pkg_cache
  install_dependencies
  install_vundle
  write_vimrc
  install_plugins
  print_summary
}

main "$@"
