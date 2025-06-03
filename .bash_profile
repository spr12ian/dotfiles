#!/bin/bash

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    fi
else
    echo "This script is intended to be run in a bash shell."
    return 1
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi
source "$HOME"/.post_profile

DEBUG=false
export DEBUG

# Check if DEBUG is set to true
if [ "$DEBUG" = "true" ]; then
    set -x # Enable debugging
else
    set +x # Disable debugging
fi

setup-symbolic-links

debug echo "Running .post_profile"

source "$HOME/.env"

focus-here

debug echo "Finished running .post_profile"

set +x
