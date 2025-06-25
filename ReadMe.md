Make sure you have zsh installed. 

then install the oh-my-zsh

you will have a .zshrc file in your home directory.

replace its content with the .zshrc file from this repository.

tham run this command to install all plugins
```bash
SH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

git clone https://github.com/Aloxaf/fzf-tab           $ZSH_CUSTOM/plugins/fzf-tab
git clone https://github.com/zsh-users/zsh-autosuggestions \
                                                     $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
                                                     $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions \
                                                     $ZSH_CUSTOM/plugins/zsh-completions
sudo apt install autojump
```

and to finish:
exec zsh

now you have my zsh setup
