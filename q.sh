CALLER=$(grep "CALLER=" ~/.ssh/authorized_keys | awk '{print $NF}' | sed 's/^CALLER=//')

sudo cp /home/$CALLER/projects/dotfiles/.bash_profile ./
sudo cp /home/$CALLER/projects/dotfiles/.bashrc ./
sudo cp /home/$CALLER/projects/dotfiles/.post_bashrc ./
