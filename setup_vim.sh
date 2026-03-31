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
write_vimrc() {
  local vimrc="$HOME/.vimrc"
  if [[ -f "$vimrc" ]]; then
    warn ".vimrc already exists — backing up to ~/.vimrc.bak"
    cp "$vimrc" "$HOME/.vimrc.bak"
  fi
  info "Writing .vimrc …"
  cat > "$vimrc" << 'VIMRC'
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'sainnhe/everforest'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

call vundle#end()            " required
filetype plugin indent on    " required

" ── Everforest theme ─────────────────────────────────────────────────────────
syntax enable
if has('termguicolors')
  set termguicolors
endif
set background=dark
let g:everforest_background              = 'hard'
let g:everforest_better_performance      = 1
let g:everforest_highlight               = 1
let g:everforest_disable_italic_comment  = 1
let g:airline_theme                      = 'everforest'
colorscheme everforest
syntax on

" ── Editor behaviour ─────────────────────────────────────────────────────────
set mouse=a
set number
set cursorline
set colorcolumn=81
set ruler
set wildmenu
set nowrap
set noswapfile
set fileformat=unix
set encoding=UTF-8

" ── Indentation (tabs, 4 spaces wide, no expansion) ──────────────────────────
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent
set noexpandtab
set smarttab

" ── Man pages inside Vim ──────────────────────────────────────────────────────
runtime! ftplugin/man.vim

" ── Key mappings ─────────────────────────────────────────────────────────────
" Netrw file explorer (Ctrl-X)
inoremap <C-X> <Esc>:Lex<CR>:vertical resize 23<CR>
nnoremap <C-X> <Esc>:Lex<CR>:vertical resize 23<CR>

" Clipboard copy / paste (system clipboard)
vnoremap <C-C> "*y
nnoremap <C-V> "*p

" Clear search highlight
nnoremap <C-S-a> :nohlsearch<CR>
VIMRC
  ok ".vimrc written"
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
