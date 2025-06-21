#!/usr/bin/env bash
set -euo pipefail

echo "📋 Running dotfile diagnostics at $(date)"
echo "────────────────────────────────────────────"

check_file() {
  local file="$1"
  if [ -f "$file" ]; then
    echo "✅ Found $file"
  else
    echo "❌ Missing $file"
  fi
}

check_function() {
  local fn="$1"
  if declare -F "$fn" &>/dev/null; then
    echo "✅ Function defined: $fn"
  else
    echo "⚠️  Function missing: $fn"
  fi
}

check_env_file() {
  if [ -f "$HOME/.env" ]; then
    echo "✅ Found .env file"
    grep -E '^[A-Z0-9_]+=.*$' "$HOME/.env" || echo "⚠️  .env contains no key=value pairs"
  else
    echo "❌ .env file missing"
  fi
}

test_run_local() {
  local cmd="$1"
  if run_local "$cmd" --version &>/dev/null; then
    echo "✅ run_local works for: $cmd"
  else
    echo "⚠️  run_local failed or command missing: $cmd"
  fi
}

resolve_symlink() {
  local file="$1"
  if [ -L "$file" ]; then
    local target
    target=$(readlink -f "$file" 2>/dev/null || realpath "$file" 2>/dev/null || echo "unresolved")
    echo "🔗 $file → $target"
  else
    echo "   $file is not a symlink"
  fi
}

# ─────────────────────────────────────────────
echo "📁 Checking expected dotfiles"
check_file "$HOME/.bashrc"
check_file "$HOME/.bash_profile"
check_file "$HOME/.post_bashrc"

echo
echo "🔐 Checking .env file"
check_env_file

echo
echo "🔧 Checking key functions"
check_function set_post_bashrc_environment
check_function source_bash_functions
check_function run_local
check_function add_path_if_exists

echo
echo "🔗 Checking dotfile symlinks"
for name in bashrc bash_profile post_bashrc; do
  resolve_symlink "$HOME/.$name"
done

echo
echo "🏃 Checking run_local for common scripts"
SYMLINKS_BIN_DIR="${SYMLINKS_BIN_DIR:-$HOME/.symlinks/bin}"
export SYMLINKS_BIN_DIR

test_run_local focus_here
test_run_local vcode

echo
echo "🛣 PATH overview"
echo "$PATH" | tr ':' '\n'

echo
echo "🎯 GITHUB_PARENT=${GITHUB_PARENT:-unset}"
echo "🎯 GITHUB_DOTFILES_DIR=${GITHUB_DOTFILES_DIR:-unset}"
echo "🎯 SYMLINKS_BIN_DIR=${SYMLINKS_BIN_DIR:-unset}"

echo
echo "✅ Dotfile diagnostics complete."
