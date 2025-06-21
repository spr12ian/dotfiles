#!/usr/bin/env bash
set -euo pipefail

SYMLINKS_BIN_DIR="$HOME/.symlinks/bin"

set_debug_log() {
    # Location of the debug log
    DEBUG_LOG="${DEBUG_LOG:-/tmp/$(basename -- "$0").log}"
    echo "The debug log file can be found at $DEBUG_LOG"
}

# Uncomment the next line to send debug messages to the log file
# set_debug_log

# Log a message with optional timestamp and indentation
_debug_log() {
    local msg="$1"
    local indent=""
    for ((i = ${#FUNCNAME[@]} - 2; i > 0; i--)); do
        indent+="  "
    done
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if declare -p DEBUG_LOG &>/dev/null; then
        echo "${timestamp} ${indent}${msg}" >>"$DEBUG_LOG"
    else
        echo "${timestamp} ${indent}${msg}"
    fi
}

log_block_start() {
    _debug_log "→ Entering ${FUNCNAME[1]}"
}

log_block_finish() {
    _debug_log "← Exiting ${FUNCNAME[1]}"
}

add_path_if_exists() {
    log_block_start

    local position="$1" dir="$2"
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        case "$position" in
        before) PATH="$dir:$PATH" ;;
        after) PATH="$PATH:$dir" ;;
        *) log_error "Invalid position: $position (use 'before' or 'after')" >&2 ;;
        esac
    fi

    log_block_finish
}

check_github_ssh() {
    log_info "🔍 Testing SSH connection to GitHub..."

    # Capture output (stderr only) because GitHub writes the message there
    output=$(ssh -o BatchMode=yes -T git@github.com 2>&1 || true)

    if grep -q "successfully authenticated" <<<"$output"; then
        # Extract GitHub username (format: "Hi username!")
        if [[ "$output" =~ Hi[[:space:]]([[:alnum:]-]+)! ]]; then
            github_user="${BASH_REMATCH[1]}"
            log_info "✅ SSH authentication with GitHub succeeded."
            log_info "   Authenticated as: $github_user"
        else
            log_warn "⚠️  SSH succeeded, but could not extract username."
            log_warn "   Raw response: $output"
        fi
    else
        log_error "❌ SSH authentication with GitHub failed." >&2
        log_error "   - Make sure your SSH key is added to https://github.com/settings/keys" >&2
        log_error "   - Run: ssh -vT git@github.com for debugging." >&2
        exit 1
    fi
}

check_not_sourced() {
    log_block_start

    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        log_error "This script must not be sourced."
        exit 1
    else
        log_info "This file is executed"
    fi

    log_block_finish
}

check_required_variables() {
    log_block_start

    log_info "🔧 Checking for required environment variables..."
    required_vars=(GITHUB_PARENT GITHUB_SETUP_REPO GITHUB_TOKEN GITHUB_USER_EMAIL GITHUB_USER_NAME)

    for var in "${required_vars[@]}"; do
        if [ -z "${!var+x}" ]; then
            log_error "$var is not set"
            exit 1
        else
            log_info "$var is set"
        fi
    done

    log_block_finish
}

focus_here() {
    log_block_start

    setup_github

    # List public repositories for a specific user
    # Filter for specific fields using jq
    # Assign results to array repos
    readarray -t repos < <(curl -s "https://api.github.com/users/${GITHUB_USER_NAME}/repos" | jq -r '.[].name')

    # Get array length
    local howManyRepos=${#repos[@]}

    if [ "${howManyRepos}" -gt 0 ]; then
        log_info "Number of repos: ${howManyRepos}"

        mkdir -p "${GITHUB_PARENT}"
        cd "${GITHUB_PARENT}" || {
            log_error "ERROR: ${GITHUB_PARENT} not found"
            exit 1
        }
        log_info "Parent directory for GitHub repos: $(pwd)"

        # Loop through array
        for repo in "${repos[@]}"; do
            log_info "Repository: ${repo}"

            if [ ! -d "${repo}" ]; then
                log_info "Cloning ${repo}..."
                # Try to clone the repository
                if gh repo clone "${GITHUB_USER_NAME}/${repo}"; then
                    log_info "Success: gh repo clone ${GITHUB_USER_NAME}/${repo}"
                else
                    log_error "ERROR: gh repo clone ${GITHUB_USER_NAME}/${repo} failed"
                fi

            fi

            log_info "Processing ${repo} complete."
        done
    else
        log_warn "No GitHub repos found for ${GITHUB_USER_NAME}"
    fi

    log_block_finish
}

install_curl() {
    log_block_start

    install_package curl

    log_block_finish
}

install_gh() {
    log_block_start

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt update

    install_package gh

    log_block_finish
}

install_git() {
    log_block_start

    install_package git

    log_block_finish
}

install_jq() {
    log_block_start

    install_package jq

    log_block_finish
}

install_package() {
    log_block_start

    local pkg="$1"

    if dpkg -s "$pkg" >/dev/null 2>&1; then
        log_info "$pkg is already installed"
    else
        log_info "Installing $pkg..."
        if sudo apt install -y "$pkg"; then
            log_info "$pkg successfully installed"
        else
            log_warn "Failed to install $pkg"
        fi
    fi

    log_block_finish
}

log_error() { echo "❌ $*" >&2; }
log_info() { echo "ℹ️  $*"; }
log_warn() { echo "⚠️  $*" >&2; }

require_bash() {
    log_block_start

    if [ -z "${BASH_VERSION:-}" ]; then
        log_error "This script must be run with bash, not sh or another shell." >&2
        exit 1
    fi

    log_block_finish
}

setup_git() {
    log_block_start

    git config --global core.autocrlf input
    git config --global core.fileMode false
    git config --global core.ignoreCase false
    git config --global init.defaultBranch main
    git config --global pull.rebase false

    log_block_finish
}

setup_github() {
    log_block_start

    setup_git

    git config --global user.email "${GITHUB_USER_EMAIL}"
    git config --global user.name "${GITHUB_USER_NAME}"

    GITHUB_HOST_NAME=$(hostnamectl --static)

    if grep -q "GitHub-${GITHUB_HOST_NAME}" ~/.ssh/id_ed25519.pub 2>/dev/null; then
        log_info "GitHub-${GITHUB_HOST_NAME} ssh key exists"
        ssh-keygen -lf ~/.ssh/id_ed25519.pub
        cat ~/.ssh/id_ed25519.pub
    else
        log_info "Generating an ed25519 SSH key for GitHub with no passphrase:"
        ssh-keygen -t ed25519 -C "GitHub-${GITHUB_HOST_NAME}" -f ~/.ssh/id_ed25519 -N ""

        log_info "Add the SSH key to GitHub by copying its contents:"
        cat ~/.ssh/id_ed25519.pub

        ssh-keygen -lf ~/.ssh/id_ed25519.pub
    fi

    check_github_ssh

    log_block_finish
}

setup_symbolic_linksX() {
    log_block_start

    original_bin_dir="${GITHUB_PARENT}/bin"

    mkdir -p "${SYMLINKS_BIN_DIR}"

    # Check source directory
    if [ ! -d "${original_bin_dir}" ]; then
        log_error "Source directory does not exist: ${original_bin_dir}"
        exit 1
    fi

    # Check target directory is writable
    if [ ! -w "${SYMLINKS_BIN_DIR}" ]; then
        log_error "Target directory is not writable: ${SYMLINKS_BIN_DIR}"
        exit 1
    fi

    shopt -s nullglob
    files=("${original_bin_dir}"/*.sh)
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        log_error "No .sh files found in ${original_bin_dir}"
        exit 1
    fi

    for file in "${files[@]}"; do
        [[ -f "$file" ]] || {
            log_warn "Source is not a regular file: $file"
            continue
        }

        # Check if file has a shebang line
        grep -q '^#!' "$file" || {
            echo "WARNING: $file is missing a shebang line"
            continue
        }

        command_file=$(basename -- "${file}" .sh)

        if [[ "$command_file" == source-* ]]; then
            mode=600
        else
            mode=700
        fi

        chmod "$mode" "$file"

        link_path="${SYMLINKS_BIN_DIR}/${command_file}"

        ln -sf "${file}" "${link_path}"
    done

    for file in "${original_bin_dir}"/*; do
        # Skip if it's a directory
        [[ -d "$file" ]] && continue

        # Skip if filename ends with .sh
        if [[ "$file" == *.sh ]]; then
            continue
        fi

        ls -l "$file"
    done

    ls -lL "${SYMLINKS_BIN_DIR}"

    log_info "Symbolic links created in ${SYMLINKS_BIN_DIR} for all .sh files in ${original_bin_dir}"

    add_path_if_exists before "SYMLINKS_BIN_DIR"

    log_info "Done."

    log_block_finish
}

link_home_dotfiles() {
    local original_dir="${GITHUB_DOTFILES_DIR:?GITHUB_DOTFILES_DIR not set}"
    local target_dir="$HOME"
    local chmod_mode=600

    if [ "$#" -eq 0 ]; then
        echo "ℹ️  No dotfiles passed in"
        return 0
    fi

    if [ ! -d "$original_dir" ]; then
        echo "❌ Original directory does not exist: $original_dir"
        return 1
    fi

    if [ ! -w "$target_dir" ]; then
        echo "❌ Target directory is not writable: $target_dir"
        return 1
    fi

    for filename in "$@"; do
        local src_file="$original_dir/.$filename"
        local dest_file="$target_dir/.$filename"

        if [ ! -f "$src_file" ]; then
            echo "⚠️  File not found: $src_file"
            continue
        fi

        chmod "$chmod_mode" "$src_file"
        ln -sf "$src_file" "$dest_file"
        echo "🔗 Linked $src_file → $dest_file"
    done

    echo "✅ Dotfiles linked into $target_dir"
}

link_scripts_in_dir() {
    local original_dir="$1"
    local target_dir="$2"
    local chmod_mode="$3"

    mkdir -p "${target_dir}"

    if [ ! -d "${original_dir}" ]; then
        echo "❌ Original directory does not exist: ${original_dir}"
        return 1
    fi

    if [ ! -w "${target_dir}" ]; then
        echo "❌ Target directory is not writable: ${target_dir}"
        return 1
    fi

    shopt -s nullglob
    local files=("${original_dir}"/*.sh)
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        echo "ℹ️  No .sh files found in ${original_dir}"
        return 0
    fi

    for file in "${files[@]}"; do
        [[ -f "$file" ]] || {
            echo "⚠️  Not a regular file: $file"
            continue
        }

        grep -q '^#!' "$file" || {
            echo "⚠️  Missing shebang: $file"
            continue
        }

        local command_file
        command_file=$(basename -- "${file}" .sh)

        chmod "${chmod_mode}" "$file"
        ln -sf "${file}" "${target_dir}/${command_file}"
    done

    for file in "${original_dir}"/*; do
        [[ -d "$file" || "$file" == *.sh ]] && continue
        ls -l "$file"
    done

    ls -lL "${target_dir}"
    echo "✅ Symbolic links created in ${target_dir} for all .sh files in ${original_dir}"
}

setup_symbolic_links() {
    local project_dir="${GITHUB_PARENT:-$HOME}/bin"
    local symlinks_dir="$HOME/.symlinks"

    link_scripts_in_dir "${project_dir}" "$symlinks_dir/bin" 700
    link_scripts_in_dir "${project_dir}/source" "$symlinks_dir/source" 600

    dot_files=(bash_profile bashrc post_bashrc)
    link_home_dotfiles "${dot_files[@]}"
}

update_linux() {
    log_block_start

    sudo apt update
    sudo apt upgrade -y

    install_curl
    install_git
    install_gh
    install_jq

    log_block_finish
}

require_bash

check_not_sourced

update_linux

check_required_variables

focus_here

setup_symbolic_links

# Check if .bashrc already has .post_bashrc

if ! grep -q ".post_bashrc" "$HOME"/.bashrc; then
    echo "Appending .post_bashrc source block to .bashrc..."
    cat <<'EOF' >>"$HOME/.bashrc"

# ============================================================
# User customisation block — added manually
# ============================================================

if [ -f "$HOME/.post_bashrc" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.post_bashrc"
fi

# ============================================================
# End of user customisation block
# ============================================================

EOF
fi

cp "$GITHUB_PARENT/$GITHUB_SETUP_REPO/.post_bashrc" "$HOME"
cp "$GITHUB_PARENT/$GITHUB_SETUP_REPO/.bash_profile" "$HOME"

log_info "✅ All GitHub repos processed and environment configured"
log_info "🧩 Config files: ~/.bash_profile, ~/.post_bashrc"
log_info "🔗 Symlinks created in: $SYMLINKS_BIN_DIR"

# Get the full path to the script
SCRIPT_PATH="$(realpath "$0")"

log_info "So far, so good. Please delete this file:"
echo rm -- "$SCRIPT_PATH"

# Print a message indicating the setup is complete
log_info "Setup complete. Please restart your terminal."
