#Each time sgoinfre has been cleaned, VSCode disappear. Meaning I have to install it again.
#Here is a script to launch to install it directly, without rocking my head.
#!/bin/bash

# ─────────────────────────────────────────────
#  install_vscode.sh
#  Installe VS Code dans ~/sgoinfre sans sudo
#  Usage : bash install_vscode.sh
# ─────────────────────────────────────────────

set -e

INSTALL_DIR="$HOME/sgoinfre/vscode"
DESKTOP_FILE="$HOME/.local/share/applications/code-sgoinfre.desktop"
SHELL_RC=""

# ── Détecter le shell ──────────────────────────
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Installation de VS Code → sgoinfre  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Supprimer l'ancienne install si elle existe ──
if [ -d "$INSTALL_DIR" ]; then
    echo "[1/5] Suppression de l'ancienne installation..."
    rm -rf "$INSTALL_DIR"
else
    echo "[1/5] Aucune ancienne installation détectée."
fi

# ── 2. Télécharger VS Code ─────────────────────
echo "[2/5] Téléchargement de VS Code (peut prendre 1-2 min)..."
mkdir -p "$INSTALL_DIR"
curl -L \
    "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" \
    -o /tmp/vscode_42.tar.gz \
    --progress-bar

# ── 3. Extraire dans sgoinfre ─────────────────
echo "[3/5] Extraction dans $INSTALL_DIR (2-5 min, soyez patient)..."
tar -xzf /tmp/vscode_42.tar.gz -C "$INSTALL_DIR" --strip-components=1
rm /tmp/vscode_42.tar.gz
echo "      Extraction terminée ✓"

# ── 4. Ajouter au PATH si pas déjà présent ────
echo "[4/5] Configuration du PATH dans $SHELL_RC..."
if ! grep -q "sgoinfre/vscode/bin" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# VS Code (installé dans sgoinfre)" >> "$SHELL_RC"
    echo 'export PATH="$HOME/sgoinfre/vscode/bin:$PATH"' >> "$SHELL_RC"
    echo "      PATH mis à jour ✓"
else
    echo "      PATH déjà configuré, rien à faire."
fi

# ── 5. Masquer l'ancienne icône système si elle existe ──
echo "[5/5] Gestion des icônes..."
if [ -f /usr/share/applications/code.desktop ]; then
    mkdir -p "$HOME/.local/share/applications"
    cp /usr/share/applications/code.desktop "$HOME/.local/share/applications/"
    if ! grep -q "Hidden=true" "$HOME/.local/share/applications/code.desktop"; then
        echo "Hidden=true" >> "$HOME/.local/share/applications/code.desktop"
        echo "      Ancienne icône système masquée ✓"
    fi
fi

# Créer un launcher .desktop pour la nouvelle install
mkdir -p "$HOME/.local/share/applications"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Visual Studio Code (sgoinfre)
Comment=Code Editing. Redefined.
Exec=$INSTALL_DIR/bin/code --unity-launch %F
Icon=$INSTALL_DIR/resources/app/resources/linux/code.png
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=TextEditor;Development;IDE;
MimeType=text/plain;
EOF
echo "      Icône créée dans le launcher ✓"

# ── Résumé ────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  Installation terminée !"
echo ""
echo "  Pour utiliser VS Code maintenant :"
echo "  → source $SHELL_RC"
echo "  → code ."
echo ""
echo "  ⚠  sgoinfre est local à cette machine."
echo "     Relance ce script sur chaque poste."
echo "══════════════════════════════════════════"
echo ""
