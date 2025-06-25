

# Zsh Setup

This is my personal Zsh setup for a pleasant developer experience in the terminal.
For german click [here](./ReadMe-de.md)

## Requirements

- **zsh** must be installed.
- [oh-my-zsh](https://ohmyz.sh/) should be installed.

## Installation

1. **Install zsh** (if not already installed):

    ```bash
    sudo apt install zsh
    ```

2. **Install oh-my-zsh**:

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

3. **Replace your .zshrc**:

    Replace the contents of your existing `~/.zshrc` file with the `.zshrc` file from this repository.

4. **Install required plugins**:

    Run the following commands to install all necessary plugins:

    ```bash
    SH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

    git clone https://github.com/Aloxaf/fzf-tab           $SH_CUSTOM/plugins/fzf-tab
    git clone https://github.com/zsh-users/zsh-autosuggestions $SH_CUSTOM/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $SH_CUSTOM/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-completions $SH_CUSTOM/plugins/zsh-completions
    sudo apt install autojump
    ```

5. **Restart your shell**:

    ```bash
    exec zsh
    ```

Now you have my Zsh setup ready to use. Enjoy!
