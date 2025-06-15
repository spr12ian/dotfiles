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

log_this bash_profile

if shopt -q login_shell; then
    echo "Login  shell"
    if [[ $- == *i* ]]; then
        echo "Interactive  shell"

        # Interactive login shell
        if is_user_env_probe; then
            echo "🚫 Skipping focus-here — VS Code userEnvProbe" >> /tmp/bash_env_debug.log
        else
            echo "✅ Running focus-here" >> /tmp/bash_env_debug.log
            run_local focus-here
        fi
    fi
fi

# shellcheck source=/dev/null
if [[ -f "$HOME/.bash_profile_exit" ]]; then
    echo "🛑 .bash_profile_exit file detected — exiting after validation"
    rm -f "$HOME/.bash_profile_exit"
    echo "=== .bash_profile finished ==="
    exit
fi

