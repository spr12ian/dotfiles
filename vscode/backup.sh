#!/usr/bin/env bash
set -e

# Detect VS Code settings path
detect_vscode_dir() {
  if grep -qi microsoft /proc/version; then
    # Detected WSL
    WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null| tr -d '\r')
    echo "/mnt/c/Users/$WINDOWS_USER/AppData/Roaming/Code/User"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Detected macOS
    echo "$HOME/Library/Application Support/Code/User"
  else
    # Detected Linux
    echo "$HOME/.config/Code/User"
  fi
}

VSCODE_SETTINGS_DIR=$(detect_vscode_dir)
CURRENT_DIR="$(dirname "$0")"
DEST_DIR="$CURRENT_DIR/User"
mkdir -p "$DEST_DIR"

SNIPPETS_DIR="$DEST_DIR/snippets"
mkdir -p "$SNIPPETS_DIR"

echo "📦 Backing up VS Code extensions..."
code --list-extensions | grep '^[a-zA-Z0-9-]\+\.[a-zA-Z0-9-]\+$' | sort > "$(dirname "$0")/extensions.txt"

echo "📂 Backing up settings to $CURRENT_DIR..."
cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$CURRENT_DIR/" 2>/dev/null || true
cp "$VSCODE_SETTINGS_DIR/settings.json" "$CURRENT_DIR/"

echo "📂 Backing up snippets to $SNIPPETS_DIR..."
shopt -s nullglob
for snippet in "$VSCODE_SETTINGS_DIR/snippets/"*; do
  cp "$snippet" "$SNIPPETS_DIR/"
done
shopt -u nullglob

echo "✅ Backup complete."
