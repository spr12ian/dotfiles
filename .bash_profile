#!/bin/bash

# Exit if not sourced in Bash
[ -n "$BASH_VERSION" ] || {
    echo "Must be sourced in Bash." >&2
    return 1
}

# Always source .bashrc if it exists (needed for interactive shells)
if [ -f "$HOME/.bashrc" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
else
    echo ".bashrc not found in $HOME." >&2
    return 1
fi

if declare -f load_post_bashrc >/dev/null; then
    load_post_bashrc
fi
