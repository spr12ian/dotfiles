# dotfiles
Speed up the setup of new development environments

Copy the .env key-value pairs from Bitwarden (other secure locations are available), minimally:
GITHUB_USER_NAME=your-username
GITHUB_SETUP_REPO=your-setup-repo
GITHUB_TOKEN=your-github-token

On initial login to a new environment

1. Create .env file

```
cat >.env
```
<kbd>Ctrl</kbd> + <kbd>V</kbd> then
<kbd>Ctrl</kbd> + <kbd>D</kbd>

2. Set environment variables from file

`set -a; source .env; set +a`

3. Copy & run the setup file from GitHub
```
curl -fsSL https://raw.githubusercontent.com/$GITHUB_USER_NAME/$GITHUB_SETUP_REPO/refs/heads/main/setup-linux.sh -o setup-linux.sh && setup-linux.sh
```
