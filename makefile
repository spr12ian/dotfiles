install:
	@bash -c 'source .post_bashrc && setup_symbolic_links'

link-dotfiles:
	@bash -c 'source .post_bashrc && link_home_dotfiles bashrc bash_profile inputrc'

show-about:
	@bash -c 'source .post_bashrc && about bash grep sed'
