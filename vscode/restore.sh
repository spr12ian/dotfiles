#!/usr/bin/env bash
set -e

# Detect VS Code user settings path
detect_vscode_dir() {
  if grep -qi microsoft /proc/version; then
    # WSL
    WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    echo "/mnt/c/Users/$WINDOWS_USER/AppData/Roaming/Code/User"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "$HOME/Library/Application Support/Code/User"
  else
    # Linux
    echo "$HOME/.config/Code/User"
  fi
}

VSCODE_SETTINGS_DIR=$(detect_vscode_dir)
CURRENT_DIR="$(dirname "$0")"
BACKUP_DIR="$CURRENT_DIR/User"

echo "📂 Restoring VS Code settings to $VSCODE_SETTINGS_DIR..."

mkdir -p "$VSCODE_SETTINGS_DIR/snippets"

# Restore settings.json
if [[ -f "$BACKUP_DIR/settings.json" ]]; then
  cp "$BACKUP_DIR/settings.json" "$VSCODE_SETTINGS_DIR/"
  echo "✅ Restored settings.json"
fi

# Restore keybindings.json
if [[ -f "$BACKUP_DIR/keybindings.json" ]]; then
  cp "$BACKUP_DIR/keybindings.json" "$VSCODE_SETTINGS_DIR/"
  echo "✅ Restored keybindings.json"
fi

# Restore snippets
SNIPPETS_SRC="$BACKUP_DIR/snippets"
if [[ -d "$SNIPPETS_SRC" ]]; then
  for snippet in "$SNIPPETS_SRC"/*; do
    cp "$snippet" "$VSCODE_SETTINGS_DIR/snippets/"
  done
  echo "✅ Restored snippets"
fi

# Restore extensions
EXT_LIST="$CURRENT_DIR/extensions.txt"
if [[ -f "$EXT_LIST" ]]; then
  echo "📦 Installing extensions from $EXT_LIST..."
  xargs -n1 code --install-extension < "$EXT_LIST"
  echo "✅ Extensions restored"
fi

echo "🎉 VS Code restore complete."
