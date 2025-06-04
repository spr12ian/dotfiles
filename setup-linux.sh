#!/bin/bash
set -euo pipefail

add_path_if_exists() {
    local position="$1" dir="$2"
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        case "$position" in
        before) PATH="$dir:$PATH" ;;
        after) PATH="$PATH:$dir" ;;
        *) echo "Invalid position: $position (use 'before' or 'after')" >&2 ;;
        esac
    fi
}

check_required_variables() {
    echo "🔧 Checking for required environment variables..."
    required_vars=(GITHUB_PARENT GITHUB_SETUP_REPO GITHUB_TOKEN GITHUB_USER_EMAIL GITHUB_USER_NAME)

    for var in "${required_vars[@]}"; do
        if [ -z "${!var+x}" ]; then
            echo "$var is not set"
            return 1
        else
            echo "$var is set"
        fi
    done
}

focus_here() {
    setup_github

    # List public repositories for a specific user
    # Filter for specific fields using jq
    # Assign results to array repos
    readarray -t repos < <(curl -s "https://api.github.com/users/${GITHUB_USER_NAME}/repos" | jq -r '.[].name')

    # Get array length
    local howManyRepos=${#repos[@]}

    if [ "${howManyRepos}" -gt 0 ]; then
        echo "Number of repos: ${howManyRepos}"

        mkdir -p "${GITHUB_PARENT}"
        cd "${GITHUB_PARENT}" || {
            echo "ERROR: ${GITHUB_PARENT} not found"
            exit 1
        }
        echo "Parent directory for GitHub repos: $(pwd)"

        # Loop through array
        for repo in "${repos[@]}"; do
            echo "Repository: ${repo}"

            if [ ! -d "${repo}" ]; then
                echo "Cloning ${repo}..."
                # Try to clone the repository
                if gh repo clone "${GITHUB_USER_NAME}/${repo}"; then
                    echo "Success: gh repo clone ${GITHUB_USER_NAME}/${repo}"
                else
                    echo "ERROR: gh repo clone ${GITHUB_USER_NAME}/${repo} failed"
                fi

            fi

            echo "Processing ${repo} complete."
        done
    else
        echo "No GitHub repos found for ${GITHUB_USER_NAME}"
    fi
}

install_curl() {
    sudo apt install -y curl
}

install_gh() {
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt update
    sudo apt install -y gh
}

install_git() {
    sudo apt install -y git
}

install_jq() {
    sudo apt install -y jq
}

setup_git() {
    echo "$0" started

    git config --global core.autocrlf input
    git config --global core.fileMode false
    git config --global core.ignoreCase false
    git config --global init.defaultBranch main
    git config --global pull.rebase false

    echo "$0" finished
}

setup_github() {
    echo "$0" started

    setup_git

    git config --global user.email "${GITHUB_USER_EMAIL}"
    git config --global user.name "${GITHUB_USER_NAME}"

    if grep -q "GitHub-${GITHUB_HOST_NAME}" ~/.ssh/id_ed25519.pub 2>/dev/null; then
        echo "GitHub-${GITHUB_HOST_NAME} ssh key exists"
        ssh-keygen -lf ~/.ssh/id_ed25519.pub
        cat ~/.ssh/id_ed25519.pub
    else
        echo "Generating an ed25519 SSH key for GitHub with no passphrase:"
        ssh-keygen -t ed25519 -C "GitHub-${GITHUB_HOST_NAME}" -f ~/.ssh/id_ed25519 -N ""

        echo "Add the SSH key to GitHub by copying its contents:"
        cat ~/.ssh/id_ed25519.pub

        ssh-keygen -lf ~/.ssh/id_ed25519.pub
    fi

    ssh -T git@github.com

    # shellcheck disable=SC2162
    read -p "Press Enter to continue..."

    echo "$0" finished
}

setup_symbolic_links() {
    source_dir="${GITHUB_PARENT}/bin"
    target_dir="$HOME/.local/bin"
    mkdir -p "${target_dir}"

    # Check source directory
    if [ ! -d "${source_dir}" ]; then
        echo "Source directory does not exist: ${source_dir}"
        exit 1
    fi

    # Check target directory is writable
    if [ ! -w "${target_dir}" ]; then
        echo "Target directory is not writable: ${target_dir}"
        exit 1
    fi

    shopt -s nullglob
    files=("${source_dir}"/*.sh)
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        echo "No .sh files found in ${source_dir}"
        exit 0
    fi

    for file in "${files[@]}"; do
        echo "Processing: ${file}"

        # Check if file has a shebang line
        grep -q '^#!' "$file" || echo "WARNING: $file is missing a shebang line"
        [[ ! -f "${file}" ]] && echo "Source is not a regular file"
        [[ ! -x "${file}" ]] && echo "Source is not executable"

        command_file=$(basename "${file}" .sh)
        link_path="${target_dir}/${command_file}"

        ln -sf "${file}" "${link_path}"
        echo "Created symlink: ${link_path} -> ${file}"

        [[ ! -x "${link_path}" ]] && echo "Link is not executable"
        [[ ! -f "${link_path}" ]] && echo "Link is not a regular file"

        echo
    done

    ls -al "${target_dir}"
    echo "Symbolic links created in ${target_dir} for all .sh files in ${source_dir}"

    add_path_if_exists before "$HOME/.local/bin"

    echo "Done."
}

update_linux() {
    sudo apt update
    sudo apt upgrade -y

    install_curl
    install_git
    install_gh
    install_jq
}

(return 0 2>/dev/null) && {
    echo "This script must not be sourced."
    return 1
}

update_linux

check_required_variables

focus_here

setup_symbolic_links

# Check if .bashrc already has .post_bashrc
if ! grep -q ".post_bashrc" "$HOME"/.bashrc; then
    # We want this to output $HOME without expansion
    # shellcheck disable=SC2016
    echo 'source "$HOME"/.post_bashrc' >>"$HOME/.bashrc"
fi

cp "$GITHUB_PARENT/$GITHUB_SETUP_REPO/.post_bashrc" "$HOME"
cp "$GITHUB_PARENT/$GITHUB_SETUP_REPO/.bash_profile" "$HOME"

# Get the full path to the script
SCRIPT_PATH="$(realpath "$0")"

echo "So far, so good. Please delete this file:"
echo rm -- "$SCRIPT_PATH"

# Print a message indicating the setup is complete
echo "Setup complete. Please restart your terminal."
