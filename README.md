# .vimrc

My personal Vim setup, ready to deploy on any fresh machine in one command.

## Quickstart

```bash
curl -fsSL https://raw.githubusercontent.com/SimonIsCoding/.vimrc/main/setup_vim.sh | bash
```

That's it. The script handles everything else.

---

## What gets installed

| Component | Details |
|---|---|
| **Vim** | via `brew` (macOS) or system package manager (Linux) |
| **Vundle** | Plugin manager, cloned into `~/.vim/bundle/Vundle.vim` |
| **everforest** | Dark colorscheme (`hard` contrast) |
| **vim-airline** | Status bar |
| **vim-airline-themes** | Airline theme set to `everforest` |

---

## Compatibility

| OS | Package manager used |
|---|---|
| macOS | Homebrew (auto-installed if missing) |
| Ubuntu / Debian | `apt` |
| Fedora | `dnf` |
| Arch | `pacman` |

---

## What the script does, step by step

1. Detects the OS
2. Installs Homebrew on macOS if not present
3. Installs `vim`, `git`, `curl` if missing
4. Clones Vundle (or pulls latest if already there)
5. Writes `~/.vimrc` (backs up any existing one to `~/.vimrc.bak`)
6. Runs `:PluginInstall` headlessly

---

## Key mappings

| Shortcut | Action |
|---|---|
| `Ctrl+X` | Toggle Netrw file explorer (23 cols) |
| `Ctrl+C` (visual) | Copy to system clipboard |
| `Ctrl+V` (normal) | Paste from system clipboard |
| `Ctrl+Shift+A` | Clear search highlight |

---

## Manual run (if you have the file locally)

```bash
chmod +x setup_vim.sh
./setup_vim.sh
```

If `curl` isn't available on a bare Linux machine:

```bash
sudo apt install curl    # Debian / Ubuntu
sudo dnf install curl    # Fedora
```
