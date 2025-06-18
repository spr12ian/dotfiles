#!/usr/bin/env bash
set -euo pipefail


# Simple dotfiles linker
# Run from the dotfiles repo root


ln -sf $PWD/.bash_profile ~/.bash_profile
ln -sf $PWD/.post_bashrc ~/.post_bashrc
ln -sf $PWD/.gitconfig ~/.gitconfig
ln -sf $PWD/.inputrc ~/.inputrc
ln -sf $PWD/.vimrc ~/.vimrc

echo "Dotfiles linked!"
