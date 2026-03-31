#!/usr/bin/env bash
# =============================================================================
#  setup_vim.sh — Bootstraps Sim's Vim environment 
#  Supports: macOS (Intel + Apple Silicon), Linux (x86_64)
# =============================================================================
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[✔]${NC} $*"; }
info() { echo -e "${CYAN}[→]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[✘]${NC} $*" >&2; exit 1; }

# ── Config ────────────────────────────────────────────────────────────────────
LOCAL_BIN="$HOME/.local/bin"
VIMRC_URL="https://raw.githubusercontent.com/SimonIsCoding/.vimrc/main/.vimrc"

# Static binary URLs (Linux x86_64)
VIM_APPIMAGE_URL="https://github.com/vim/vim-appimage/releases/download/v9.1.1006/GVim-v9.1.1006.glibc2.29-x86_64.AppImage"
GIT_PORTABLE_URL="https://github.com/nicowillis/git-static/releases/download/v2.39.0/git-linux-amd64"
CURL_STATIC_URL="https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64"

# ── OS detection ──────────────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
  esac
  ARCH="$(uname -m)"
  ok "OS detected: $OS ($ARCH)"
}

# ── ~/.local/bin setup ────────────────────────────────────────────────────────
setup_local_bin() {
  mkdir -p "$LOCAL_BIN"
  export PATH="$LOCAL_BIN:$PATH"
  # Persist across sessions
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [[ -f "$rc" ]] && ! grep -q 'HOME/.local/bin' "$rc" 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
      info "Added ~/.local/bin to PATH in $(basename "$rc")"
    fi
  done
  ok "~/.local/bin ready"
}

# ── Homebrew (macOS only) ────────────────────────────────────
install_homebrew() {
  if [[ "$OS" != "macos" ]]; then return; fi
  if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
    return
  fi
  info "Installing Homebrew …"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to PATH for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
  ok "Homebrew installed"
}

# ── Generic download helper ───────────────────────────────────────────────────
download() {
  local url=$1 dest=$2
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    die "Neither curl nor wget found. Cannot download files."
  fi
}

# ── curl bootstrap (chicken-and-egg) ─────────────────────────────────────────
ensure_curl() {
  if command -v curl &>/dev/null; then
    ok "curl already available"
    return
  fi
  if command -v wget &>/dev/null; then
    info "curl not found — downloading static curl via wget …"
    wget -qO "$LOCAL_BIN/curl" "$CURL_STATIC_URL"
    chmod +x "$LOCAL_BIN/curl"
    ok "Static curl installed to ~/.local/bin"
    return
  fi
  die "Neither curl nor wget found on this machine."
}

# ── Linux static binary fallbacks ────────────────────────────────────────────
install_vim_static() {
  local dest="$LOCAL_BIN/vim"
  info "Downloading Vim AppImage …"
  download "$VIM_APPIMAGE_URL" "$dest"
  chmod +x "$dest"
  "$dest" --version &>/dev/null \
    || die "Vim AppImage failed. Kernel may be too old (needs glibc >= 2.29)."
  ok "Vim installed to ~/.local/bin"
}

install_git_static() {
  local dest="$LOCAL_BIN/git"
  info "Downloading static git binary …"
  download "$GIT_PORTABLE_URL" "$dest"
  chmod +x "$dest"
  ok "git installed to ~/.local/bin"
}

# ── Ensure a tool is available ────────────────────────────────────────────────
ensure_tool() {
  local cmd=$1 brew_pkg=$2 fallback_fn=$3
  if command -v "$cmd" &>/dev/null; then
    ok "$cmd already available"
    return
  fi
  if [[ "$OS" == "macos" ]]; then
    info "Installing $brew_pkg via Homebrew …"
    brew install "$brew_pkg"
    ok "$brew_pkg installed"
  else
    "$fallback_fn"
  fi
}

# ── Install core dependencies ─────────────────────────────────────────────────
install_dependencies() {
  info "Checking core dependencies …"
  ensure_curl
  ensure_tool vim vim install_vim_static
  ensure_tool git git install_git_static
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

# ── .vimrc (pulled from GitHub) ───────────────────────────────────────────────
write_vimrc() {
  local vimrc="$HOME/.vimrc"
  if [[ -f "$vimrc" ]]; then
    warn ".vimrc already exists — backing up to ~/.vimrc.bak"
    cp "$vimrc" "$HOME/.vimrc.bak"
  fi
  info "Downloading .vimrc from GitHub …"
  download "$VIMRC_URL" "$vimrc" \
    || die "Failed to download .vimrc from $VIMRC_URL"
  ok ".vimrc downloaded"
}

# ── Plugin installation ───────────────────────────────────────────────────────
install_plugins() {
  info "Installing Vim plugins via Vundle …"
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
  echo -e "  ${CYAN}~/.vimrc${NC}              pulled from GitHub"
  echo -e "  ${CYAN}~/.vim/bundle/${NC}        Vundle + plugins"
  echo -e "  ${CYAN}~/.local/bin/${NC}         user binaries"
  echo -e "  ${CYAN}colorscheme${NC}           everforest (dark/hard)"
  echo ""
  echo -e "  ${YELLOW}Reload your shell${NC} → ${CYAN}source ~/.bashrc${NC}  or  ${CYAN}source ~/.zshrc${NC}"
  echo -e "  Then open Vim. Install ${YELLOW}:PluginInstall${NC} if a plugin is missing."
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║      Sim's Vim Setup Script          ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${NC}"

  detect_os
  setup_local_bin
  install_homebrew
  install_dependencies
  install_vundle
  write_vimrc
  install_plugins
  print_summary
}

main "$@"
