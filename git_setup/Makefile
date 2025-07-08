.DEFAULT_GOAL := install

HOME_DIR := $(HOME)
CONFIG_DIR := $(CURDIR)

.PHONY: install gitconfig gitignore

install: gitconfig gitignore
	@echo "✅ Git configuration installed."

gitconfig:
	cp $(CONFIG_DIR)/gitconfig ~/.gitconfig

gitignore:
	cp $(CONFIG_DIR)/gitignore_global ~/.gitignore_global
