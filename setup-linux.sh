#!/bin/bash
set -euo pipefail

# Check if the script is being sourced
(return 0 2>/dev/null) || {
    echo "This script should be sourced, not executed."
    exit 1
}

echo "🔧 Starting setup-linux..."
if [ -f delete-me-setup-linux.env ]; then
    echo "Sourcing delete-me-setup-linux.env"
    set -a
    # shellcheck source=/dev/null
    source delete-me-setup-linux.env
    set +a
else
    echo "No delete-me-setup-linux.env found, proceeding with setup."
fi

echo "🔧 Checking for required environment variables..."
required_vars=(GITHUB_TOKEN GITHUB_SETUP_REPO GITHUB_USER_NAME)

for var in "${required_vars[@]}"; do
    if [ -z "${!var+x}" ]; then
        echo "$var is not set"
        return 1
    else
        echo "$var is set"
    fi
done

# === Sanitize ===
if [ -f delete-me-setup-linux.env ]; then
    echo "Deleting delete-me-setup-linux.env"
    rm delete-me-setup-linux.env
fi

# === Authenticate GitHub CLI ===
echo "🔐 Logging in to GitHub CLI..."
gh auth login

# Check if .bashrc already has .post_bashrc
if ! grep -q ".post_bashrc" "$HOME"/.bashrc; then
    # We want this to output $HOME without expansion
    # shellcheck disable=SC2016
    echo 'source "$HOME"/.post_bashrc' >>"$HOME/.bashrc"
fi

echo "This script will now delete itself."

# Get the full path to the script
SCRIPT_PATH="$(realpath "$0")"

# Delete the script
rm -- "$SCRIPT_PATH"

echo "Script deleted successfully."
# Source the .bash_profile to apply changes immediately
# shellcheck source=/dev/null
source "$HOME/.bash_profile" || {
    echo "Failed to source .bash_profile. Please run 'source $HOME/.bash_profile' manually."
}
# Print a message indicating the setup is complete
echo "Setup complete. Please restart your terminal or run 'source $HOME/.bash_profile' to apply changes."
