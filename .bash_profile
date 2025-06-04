#!/bin/bash

[ -n "$BASH_VERSION" ] || {
    echo "Must be sourced in Bash." >&2
    return 1
}

if [ ! -f "$HOME/.bashrc" ]; then
    echo ".bashrc not found in $HOME." >&2
    return 1
fi

# .bashrc sources .post_bashrc
# .post_bashrc sources .env
# .post_bashrc adds "$HOME/.local/bin" to the PATH
# shellcheck source=/dev/null
source "$HOME/.bashrc"

run_local() {
    local cmd="$1"
    shift

    local local_cmd="$HOME/.local/bin/$cmd"

    # Check: file exists and is executable in .local/bin
    if [ ! -x "$local_cmd" ]; then
        echo "Command '$cmd' not found or not executable in $HOME/.local/bin." >&2
        return 1
    fi

    # Check: it's the first found in PATH
    local resolved
    resolved="$(command -v "$cmd" 2>/dev/null)"
    if [ "$resolved" != "$local_cmd" ]; then
        echo "Command '$cmd' is not resolved to $HOME/.local/bin first in PATH (resolved to $resolved)." >&2
        return 1
    fi

    # Safe to run
    "$local_cmd" "$@"
}

echo "Running .bash_profile"

run_local focus-here

echo "Finished running .bash_profile"
