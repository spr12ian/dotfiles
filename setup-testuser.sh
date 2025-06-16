#!/bin/bash
set -euo pipefail

# --- CONFIGURATION ---
# Test user to create:
TEST_USER="testuser"
# Password to set:
TEST_PASSWORD="test"
COPY_DOTFILES=true
COPY_SSH_FILES=true

TEST_USER_HOME="/home/${TEST_USER}"

add_user() {
  # --- ADD USER ---
  if getent passwd "${TEST_USER}" >/dev/null; then
    echo "User ${TEST_USER} already exists."
    exit 1
  fi

  echo "Creating user ${TEST_USER}..."
  sudo adduser --disabled-password --gecos "" ${TEST_USER}
  echo "${TEST_USER}:$TEST_PASSWORD" | sudo chpasswd
}

add_user_to_sudo_group() {
  # --- ADD TO SUDO GROUP ---
  echo "Adding ${TEST_USER} to sudo group..."
  sudo usermod -aG sudo ${TEST_USER}
}

check_requirements() { 
  if ! ssh_server_is_running; then  
    echo "⚠️ SSH server not running. You may need to start it with: sudo systemctl start ssh"
    exit 1
  fi

  if ! variable_exists "GITHUB_PARENT"; then
    echo "⚠️ Environment variable GITHUB_PARENT is not set"
    exit 1
  fi
}

copy_dotfiles() {
  # --- COPY DOTFILES ---
  local dotfiles_dir=$GITHUB_PARENT/dotfiles
  if [ ! -d "$dotfiles_dir" ]; then
    echo "Directory $dotfiles_dir not found"
  fi

  echo "Copying dotfiles..."
  for file in .hushlogin .bash_profile .bashrc .post_bashrc .bash_profile_exit; do
    if [ -f "$dotfiles_dir/$file" ]; then
      sudo cp "$dotfiles_dir/$file" "${TEST_USER_HOME}"
      sudo chown "${TEST_USER}:${TEST_USER}" "${TEST_USER_HOME}/$file"
    fi
  done
  sudo cp "$HOME/.env" "${TEST_USER_HOME}"
  sudo chown "${TEST_USER}:${TEST_USER}" "${TEST_USER_HOME}/.env"
}

copy_ssh_keys() {
  # --- OPTIONAL: COPY SSH KEYS ---
  if [ -d "$HOME/.ssh" ]; then
    echo "Copying SSH keys..."
    sudo cp -r "$HOME/.ssh" ${TEST_USER_HOME}
    sudo chown -R ${TEST_USER}:${TEST_USER} ${TEST_USER_HOME}/.ssh
    sudo chmod 700 ${TEST_USER_HOME}/.ssh
    if compgen -G "${TEST_USER_HOME}/.ssh/*" >/dev/null; then
      sudo chmod 600 ${TEST_USER_HOME}/.ssh/*
    fi
  fi
}

enable_quick_ssh_login() {
  if [ -f "$HOME/.ssh/id_ed25519_${TEST_USER}" ]; then
    echo "SSH key $HOME/.ssh/id_ed25519_${TEST_USER} already exists, skipping generation."
  else
    echo "Generating SSH key for ${TEST_USER}..."
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519_${TEST_USER}" -N "" -q -C "CALLER=$(whoami)"
  fi

  ssh-copy-id -i "$HOME/.ssh/id_ed25519_${TEST_USER}.pub" ${TEST_USER}@localhost
}

main() {
  check_requirements

  add_user
  add_user_to_sudo_group

  $COPY_DOTFILES && copy_dotfiles # test the dotfiles behave as expected
  $COPY_SSH_FILES && copy_ssh_keys # test GitHub access

  enable_quick_ssh_login

  validate_bashrc_behavior
  validate_bash_profile_behavior

  echo "Now try: ssh -i $HOME/.ssh/id_ed25519_${TEST_USER} ${TEST_USER}@localhost"
}

ssh_server_is_running() {
  if pgrep -x sshd >/dev/null; then
    return 0
  else
    return 1
  fi
}

validate_dotfile_behavior() {
  local file=$1
  local dotfile=".$file"
  local log_file="/tmp/${TEST_USER}_${file}_dump.txt"
  local ssh_opts=(
    -tt
    -i "$HOME/.ssh/id_ed25519_${TEST_USER}"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
  )

  # Write out current dotfile content to log
  {
    echo -e "=== Contents of ${TEST_USER_HOME}/${dotfile} ==="
    sudo cat "${TEST_USER_HOME}/${dotfile}"
    echo -e "\n=== End of ${TEST_USER_HOME}/${dotfile} ===\n"
  } > "${log_file}"

  if [[ "$file" == "bashrc" ]]; then
    {
      echo -e "=== Contents of ${TEST_USER_HOME}/.post_bashrc ==="
      sudo cat "${TEST_USER_HOME}/.post_bashrc"
      echo -e "\n=== End of ${TEST_USER_HOME}/.post_bashrc ===\n"
    } >> "${log_file}"
  fi

  echo "Validating ${dotfile} behavior for ${TEST_USER}..."
  echo "There should be a logfile at ${log_file}"

  set -xv

  if [[ "$file" == "bashrc" ]]; then
    ssh "${ssh_opts[@]}" "${TEST_USER}@localhost" \
    "TEST_DOTFILE_NAME='post_bashrc' bash -i" >> "${log_file}" 2>&1
    #"TEST_DOTFILE_NAME=${TEST_DOTFILE_NAME@Q} bash -i" >> "${log_file}" 2>&1
  else
    ssh "${ssh_opts[@]}" "${TEST_USER}@localhost" \
    "TEST_DOTFILE_NAME='bash_profile' bash --login -i" >> "${log_file}" 2>&1
  fi
  
  echo "The log file can be found at ${log_file}"

  set +xv

  if grep -q "dotfile_test finished" "${log_file}"; then
    echo "✅ ${dotfile} finished!"
  else
    echo "❌ ${dotfile} appears to have a problem."
    return 1
  fi
}


validate_bash_profile_behavior() {
  validate_dotfile_behavior bash_profile
}

validate_bashrc_behavior() {
  validate_dotfile_behavior bashrc
}

variable_exists() {
  local variable_name=$1
  [[ "${!variable_name+x}" == "x" ]]
}

main "$@"
