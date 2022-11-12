#!/usr/bin/env bash

EXTENSIONS=${EXTENSIONS:-"zsh-syntax-highlighting zsh-autocomplete vscode laravel docker colored-man-pages command-not-found"}
USERNAME=${USERNAME:-"automatic"}

# Install the necessary packages
sudo apt update
sudo apt install -y zsh exa

# Install and configure oh my zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Themes

# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sed -i '/ZSH_THEME=/s/"[^"][^"]*"/"powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Plugins

# Syntax highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Autocomplete
git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete

# Alternative autocomplete (zsh-autosuggestions)
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Exa aliases
# git clone https://github.com/DarrinTisdale/zsh-aliases-exa.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-aliases-exa
# Add exa aliases manually until the official build uses the git features
echo "alias ls='exa'" >> ~/.zshrc
echo "alias l='exa -lbF'" >> ~/.zshrc
echo "alias ll='exa -lbGF'" >> ~/.zshrc
echo "alias llm='exa -lbGd --sort=modified'" >> ~/.zshrc
echo "alias la='exa -lbHigUmuSa --time-style=long-iso --color-scale'" >> ~/.zshrc
echo "alias lx='exa -lbHigUmuSa@ --time-style=long-iso --color-scale'" >> ~/.zshrc


# Applying in .zshrc
sed -i '/plugins=/s/(\([^(][^)]*\))/(\1 '"$EXTENSIONS"')/' ~/.zshrc



# Clean up

sudo apt -y autoremove
sudo apt -y clean
sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

echo "Done !"