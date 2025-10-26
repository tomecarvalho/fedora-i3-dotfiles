# Set Qt apps to follow qt5ct
export QT_QPA_PLATFORMTHEME=qt5ct

## NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # Load NVM
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # Load NVM bash_completion
# Prepend Node bin from default NVM version
export PATH="$NVM_DIR/versions/node/$(nvm version)/bin:$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac