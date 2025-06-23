#!/usr/bin/env bash

# Always source .bashrc if it exists (needed for interactive shells)
if [ -f "$HOME/.bashrc" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
else
    echo ".bashrc not found in $HOME." >&2
    return 1
fi

# ─────────────────────────────────────────────
# Execute commands
# ─────────────────────────────────────────────

declare -p TEST_DOTFILE_NAME &>/dev/null && start_dotfile_test

if shopt -q login_shell; then
    if [[ $- == *i* ]]; then
        # Interactive login shell
        if is_user_env_probe; then
            declare -p TEST_DOTFILE_NAME &>/dev/null && echo "🚫 Skipping focus-here — VS Code userEnvProbe"
        else
            declare -p TEST_DOTFILE_NAME &>/dev/null && echo "✅ Running focus-here"
            run_local focus_here
        fi
    fi
fi

declare -p TEST_DOTFILE_NAME &>/dev/null && finish_dotfile_test bash_profile

# Created by `pipx` on 2025-06-23 09:40:06
export PATH="$PATH:/home/probity/.local/bin"
