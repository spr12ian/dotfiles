#!/bin/bash
set -euo pipefail

# --- CONFIGURATION ---
CURRENT_USER="$(whoami)"
# Test user to create:
TEST_USER="testuser"
# Password to set:
TEST_PASSWORD="test"

# --- ADD USER ---
echo "Creating user $TEST_USER..."
sudo adduser --disabled-password --gecos "" $TEST_USER
echo "$TEST_USER:$TEST_PASSWORD" | sudo chpasswd

# --- ADD TO SUDO GROUP ---
echo "Adding $TEST_USER to sudo group..."
sudo usermod -aG sudo $TEST_USER


copy_dotfiles() {
  # --- COPY DOTFILES ---
  echo "Copying dotfiles..."
  for file in .bashrc .bash_profile .profile .gitconfig .vimrc; do
    if [ -f /home/"$CURRENT_USER"/$file ]; then
      sudo cp /home/"$CURRENT_USER"/$file /home/$TEST_USER/
      sudo chown $TEST_USER:$TEST_USER /home/$TEST_USER/$file
    fi
  done
}

copy_ssh_keys() {
  # --- OPTIONAL: COPY SSH KEYS ---
  if [ -d /home/"$CURRENT_USER"/.ssh ]; then
    echo "Copying SSH keys..."
    sudo cp -r /home/"$CURRENT_USER"/.ssh /home/$TEST_USER/
    sudo chown -R $TEST_USER:$TEST_USER /home/$TEST_USER/.ssh
    sudo chmod 700 /home/$TEST_USER/.ssh
    if compgen -G "/home/$TEST_USER/.ssh/*" >/dev/null; then
      sudo chmod 600 /home/$TEST_USER/.ssh/*
    fi
  fi
}

# Uncomment as required
#copy_dotfiles
copy_ssh_keys

# Optional: remove old key first (uncomment if you want this behavior)
# rm -f ~/.ssh/id_ed25519_$TEST_USER ~/.ssh/id_ed25519_$TEST_USER.pub

# OR: skip generation if key exists
if [ -f ~/.ssh/id_ed25519_$TEST_USER ]; then
  echo "SSH key ~/.ssh/id_ed25519_$TEST_USER already exists, skipping generation."
else
  echo "Generating SSH key for $TEST_USER..."
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_$TEST_USER -N "" -q -C "CALLER=$(whoami)"
fi

ssh-copy-id -i ~/.ssh/id_ed25519_$TEST_USER.pub $TEST_USER@localhost

echo "Setup complete."

echo "Now try: ssh -i ~/.ssh/id_ed25519_$TEST_USER $TEST_USER@localhost"
