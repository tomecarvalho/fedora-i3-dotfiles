# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
export NVM_LAZY_LOAD=true
plugins=(git zsh-nvm zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

# gnome-keyring environment variables
[ -f ~/.gnome-keyring-env ] && . ~/.gnome-keyring-env

# zoxide
eval "$(zoxide init zsh)"

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# zsh-syntax-highlighting
ZSH_SYNTAX_HIGHLIGHTING="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "$ZSH_SYNTAX_HIGHLIGHTING" ] && . "$ZSH_SYNTAX_HIGHLIGHTING"

# Aliases
[ -f ~/.aliases ] && . ~/.aliases

# starship.rs
eval "$(starship init zsh)"

# .xprofile
[ -f ~/.xprofile ] && . ~/.xprofile