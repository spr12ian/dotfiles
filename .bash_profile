#!/bin/bash
echo "TEST_DOTFILE_NAME: $TEST_DOTFILE_NAME"
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

declare -p TEST_DOTFILE_NAME &>/dev/null && start_dotfile_test "$TEST_DOTFILE_NAME"

if shopt -q login_shell; then
    declare -p TEST_DOTFILE_NAME &>/dev/null && echo "Login shell"
    if [[ $- == *i* ]]; then
        declare -p TEST_DOTFILE_NAME &>/dev/null && echo "Interactive shell"

        # Interactive login shell
        if is_user_env_probe; then
            declare -p TEST_DOTFILE_NAME &>/dev/null && echo "🚫 Skipping focus-here — VS Code userEnvProbe"
        else
            declare -p TEST_DOTFILE_NAME &>/dev/null && echo "✅ Running focus-here"
            run_local focus-here
        fi
    fi
fi

declare -p TEST_DOTFILE_NAME &>/dev/null && finish_dotfile_test
