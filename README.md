# dotfiles

Speed up the setup of new development environments
Four steps:

1. Copy the .env key-value pairs from Bitwarden [linux] (other secure locations are available), minimally:
   GITHUB_USER_NAME=your-username
   GITHUB_REPO_SETUP=your-setup-repo
   GITHUB_TOKEN=your-github-token

On initial login to a new environment

2. Create .env file

```
cat >.env
```

<kbd>Ctrl</kbd> + <kbd>V</kbd> then
<kbd>Ctrl</kbd> + <kbd>D</kbd>

3. Set environment variables from file

`set -a; source .env; set +a`

4. Copy & run the setup file from GitHub

```
curl -fsSL "https://raw.githubusercontent.com/$GITHUB_USER_NAME/$GITHUB_REPO_SETUP/refs/heads/main/setup_linux.sh?nocache=$(date +%s)" -o setup_linux.sh && bash setup_linux.sh &>setup_linux.log
```

# Use setup-testuser.sh to setup a test user

# User cleanup-testuser.sh to cleanup afterwards

This should map to an ssh key on GitHub
`sudo ssh-keygen -lf .ssh/id_ed25519.pub`
