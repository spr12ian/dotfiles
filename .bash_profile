#!/bin/bash

# Always source .bashrc if it exists (needed for interactive shells)
if [ -f "$HOME/.bashrc" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
else
    echo ".bashrc not found in $HOME." >&2
    exit 1
fi
