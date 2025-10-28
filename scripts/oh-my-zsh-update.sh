#!/usr/bin/env zsh

echo "Updating oh-my-zsh using custom dir symlink workaround..."

OMZ_DIR="$HOME/.oh-my-zsh"
ZSHRC="$HOME/.zshrc"

# Backup existing oh-my-zsh custom directory (symlinked to dotfiles)
if [ -L "$OMZ_DIR/custom" ]; then
    mv "$OMZ_DIR/custom" "$OMZ_DIR/custom_backup"
    echo "Backed up existing custom directory."
fi

# Modify .zshrc to uncomment ZSH_CUSTOM line
# Make sure to adjust the path if necessary
sed -i.bak '/^#ZSH_CUSTOM=/s/^#//' "$ZSHRC"
echo "Uncommented ZSH_CUSTOM line in .zshrc."

# Source .zshrc to apply changes
source "$ZSHRC"

# Run oh-my-zsh update
omz update

# Restore the custom directory symlink
if [ -d "$OMZ_DIR/custom_backup" ]; then
    mv "$OMZ_DIR/custom_backup" "$OMZ_DIR/custom"
    echo "Restored custom directory symlink."
fi

# Comment back the ZSH_CUSTOM line in .zshrc
sed -i.bak '/^ZSH_CUSTOM=/s/^/#/' "$ZSHRC"