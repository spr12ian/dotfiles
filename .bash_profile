#!/bin/bash

# Always source .bashrc if it exists (needed for interactive shells)
if [ -f "$HOME/.bashrc" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
else
    echo ".bashrc not found in $HOME." >&2
    exit 1
fi

# ─────────────────────────────────────────────
# Execute commands
# ─────────────────────────────────────────────

if shopt -q login_shell && [[ $- == *i* ]]; then
    # Interactive login shell
    if is_user_env_probe; then
        echo "🚫 Skipping focus-here — VS Code userEnvProbe" >> /tmp/bash_env_debug.log
    else
        echo "✅ Running focus-here" >> /tmp/bash_env_debug.log
        run_local focus-here
    fi
fi
