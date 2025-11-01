# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# gnome-keyring environment variables
[ -f ~/.gnome-keyring-env ] && . ~/.gnome-keyring-env

# Load NVM. ZSH uses zsh-nvm as a better alternative, because it allows lazy loading.
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # Load NVM
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # Load NVM bash_completion

# Aliases
[ -f ~/.aliases ] && . ~/.aliases
[ -f ~/.private.aliases ] && . ~/.private.aliases

# .xprofile
[ -f ~/.xprofile ] && . ~/.xprofile