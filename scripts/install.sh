#!/usr/bin/env bash

JETBRAINS_MONO_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
INTER_FONT_URL="https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip"
OH_MY_ZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"

set -euo pipefail

# Default, ordered list of descriptive step names
ALL_STEPS=(
  scripts_permission
  dnf_up
  rpm_fusion
  copr
  dnf_install
  flathub
  flatpak_install
  snap_install
  pip_install
  luarocks
  vscode
  chrome
  node
  pnpm_install
  oh_my_zsh
  default_zsh
  jetbrains_mono_font
  inter_font
  gsettings_theme
  lightdm
  snapper
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGS_DIR="$SCRIPT_DIR/../packages/general"

source "$SCRIPT_DIR/utils.sh"

scripts_permission() {
  echo "[scripts_permission] Add run permission to scripts"

  STOW_DIR="$SCRIPT_DIR/../stow"

  chmod +x "$SCRIPT_DIR/utils.sh"
  chmod +x "$SCRIPT_DIR/install-work.sh"
  chmod +x "$SCRIPT_DIR/secure-boot-key.sh"
  chmod +x "$SCRIPT_DIR/nvidia-drivers.sh"
  chmod +x "$SCRIPT_DIR/oh-my-zsh-update.sh"
  chmod +x "$STOW_DIR/i3/.config/i3/scripts/gnome-keyring.sh"
  chmod +x "$STOW_DIR/rofi/.config/rofi/scripts/rofi-power-menu.sh"

  echo "[scripts_permission] Run permission added to scripts"
}

dnf_up() {
  echo "[dnf_up] Update packages"
  sudo dnf up -y --refresh
}

rpm_fusion() {
  echo "[rpm_fusion] Enable RPM Fusion Free and Nonfree"
  sudo dnf in -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf in -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

copr() {
  echo "[copr] Enable COPR repository for lazygit"
  sudo dnf copr enable -y dejan/lazygit
}

dnf_install() {
  echo "[dnf_install] Install DNF packages"
  PKG_FILE="$PKGS_DIR/dnf.txt"

  local packages=($(read_package_list "$PKG_FILE"))

  echo "[dnf_install] Installing ${#packages[@]} packages with dnf..."
  sudo dnf in -y "${packages[@]}"

  echo "[dnf_install] Removing unnecessary packages"
  sudo dnf rm -y xfce4-terminal volumeicon

  echo "[dnf_install] Replacing ffmpeg-free with ffmpeg"
  sudo dnf in -y ffmpeg --allowerasing
}

flathub() {
  echo "[flathub] Enable Flathub"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

flatpak_install() {
  echo "[flatpak_install] Install Flatpak packages"
  PKG_FILE="$PKGS_DIR/flatpak.txt"

  local packages=($(read_package_list "$PKG_FILE"))

  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "[flatpak_install] No packages to install"
    return
  fi

  echo "[flatpak_install] Installing ${#packages[@]} packages with flatpak..."
  for package in "${packages[@]}"; do
    flatpak install -y flathub "$package"
  done
}

snap_install() {
  echo "[snap_install] Install Snap packages"
  PKG_FILE="$PKGS_DIR/snap.txt"

  local packages=($(read_package_list "$PKG_FILE"))

  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "[snap_install] No packages to install"
    return
  fi

  echo "[snap_install] Enabling snapd service..."
  sudo systemctl enable --now snapd.socket
  sudo ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true

  echo "[snap_install] Installing ${#packages[@]} packages with snap..."
  for package in "${packages[@]}"; do
    sudo snap install "$package"
  done
}

pip_install() {
  echo "[pip_install] Install pip packages"
  PKG_FILE="$PKGS_DIR/pip.txt"

  if [[ ! -f "$PKG_FILE" ]]; then
    echo "[pip_install] No pip package list found at $PKG_FILE, skipping"
    return
  fi

  echo "[pip_install] Installing pip packages..."
  pip install --user --requirement "$PKG_FILE"
}

luarocks() {
  echo "[luarocks] Install LuaRocks via Hererocks (Lua 5.1) for LazyVim"
  hererocks ~/.local/share/nvim/lazy-rocks/hererocks --lua 5.1 --luarocks latest
}

vscode() {
  echo "[vscode] Add VS Code repository and install Code"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
  echo "[vscode] Install VS Code"
  sudo dnf check-update || true
  sudo dnf in -y code
}

chrome() {
  echo "[chrome] Enable Chrome repository and install it"
  sudo dnf config-manager setopt google-chrome.enabled=1
  sudo dnf in -y google-chrome-stable
}

oh_my_zsh() {
  echo "[oh_my_zsh] Install oh-my-zsh"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "oh-my-zsh is already installed at $HOME/.oh-my-zsh"
  else
    sh -c "$(curl -fsSL $OH_MY_ZSH_INSTALL_URL)"
    # Remove the custom directory, because stow will replace it
    rm -rf "$HOME/.oh-my-zsh/custom"
    echo "[oh_my_zsh] [!] The rm command to remove ~/.oh-my-zsh/custom may be executed before oh-my-zsh finishes its installation. In that case, make sure to manually run 'rm -rf ~/.oh-my-zsh/custom' after this script completes."
  fi

  # Install starship
  if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
}

default_zsh() {
  echo "[default_zsh] Make zsh the default shell"

  if ! command -v zsh &> /dev/null; then
    echo "zsh is not installed. Please install zsh first." >&2
    exit 1
  fi

  chsh -s "$(command -v zsh)"
}

jetbrains_mono_font() {
  echo "[jetbrains_mono_font] Install JetBrains Mono Nerd Font"

  FONT_DIR="/usr/local/share/fonts/JetBrainsMonoNerdFont"

  if fc-list | grep -q "JetBrainsMonoNerdFont"; then
    echo "JetBrains Mono Nerd Font is already installed"
    return
  fi
  
  # Create the font directory, if needed
  sudo mkdir -p "$FONT_DIR"

  # Download into a temporary ZIP file, unzip, and clean up the temp file
  TMP_ZIP="$(mktemp --suffix=.zip)"
  curl -L -o "$TMP_ZIP" "$JETBRAINS_MONO_FONT_URL"
  sudo unzip -o "$TMP_ZIP" -d "$FONT_DIR"
  rm "$TMP_ZIP"

  # Update font cache
  sudo fc-cache -fv

  echo "JetBrains Mono Nerd Font installed to $FONT_DIR"
}

inter_font() {
  echo "[inter_font] Install Inter Font"

  FONT_DIR="/usr/local/share/fonts/Inter"

  if fc-list | grep -q "Inter"; then
    echo "Inter Font is already installed"
    return
  fi
  
  # Create the font directory, if needed
  sudo mkdir -p "$FONT_DIR"

  # Download into a temporary ZIP file, unzip, and clean up the temp file
  TMP_ZIP="$(mktemp --suffix=.zip)"
  curl -L -o "$TMP_ZIP" "$INTER_FONT_URL"
  sudo unzip -o "$TMP_ZIP" -d "$FONT_DIR"
  rm "$TMP_ZIP"

  # Update font cache
  sudo fc-cache -fv

  echo "Inter Font installed to $FONT_DIR"
}

gsettings_theme() {
  echo "[gsettings_theme] Set dark mode and theme in gsettings"
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  gsettings set org.gnome.desktop.interface gtk-theme 'Mint-Y-Dark-Gruvbox'
}

node() {
  echo "[node] Removing Node packages and installing NVM, PNPM"
  sudo dnf remove -y nodejs nodejs-docs nodejs-full-i18n nodejs-npm

  # Install NVM if not already installed in ~/.nvm
  if [[ -d "$HOME/.nvm" ]]; then
    echo "[node] NVM is already installed"
  else
    echo "[node] Installing NVM"
    curl -o- "$NVM_INSTALL_URL" | bash
  fi

  # Load NVM
  NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  echo "[node] Installing latest LTS version of Node via NVM"
  nvm install --lts

  echo "[node] Setting LTS as default Node version"
  nvm use --lts
  nvm alias default node

  echo "[node] Installing PNPM globally via NPM"
  npm install -g pnpm

  echo "[node] Set up PNPM global packages directory"
  pnpm setup
}

pnpm_install() {
  echo "[pnpm_install] Install PNPM packages"
  PKG_FILE="$PKGS_DIR/pnpm.txt"

  if [[ ! -f "$PKG_FILE" ]]; then
    echo "[pnpm_install] No PNPM package list found at $PKG_FILE, skipping"
    return
  fi

  echo "[pnpm_install] Installing PNPM packages..."
  pnpm add -g --filter global --workspace-root --requirement "$PKG_FILE"
}

docker() {
  sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf in -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl start docker
  sudo groupadd docker
  sudo usermod -aG docker $USER
}

lightdm() {
  echo "[lightdm] Configuring NumLock in LightDM"

  # If /etc/lightdm/lightdm.conf exists
  if [[ -f /etc/lightdm/lightdm.conf ]]; then
    FILE="/etc/lightdm/lightdm.conf"

    # Warn if numlockx is not available
    if ! command -v numlockx >/dev/null 2>&1; then
      echo "[lightdm] Warning: 'numlockx' is not installed; the greeter script may not work until it's installed."
    fi

    # If there is already an uncommented greeter-setup-script, do not overwrite it
    if grep -Eq '^[[:space:]]*greeter-setup-script[[:space:]]*=' "$FILE"; then
      echo "[lightdm] Existing greeter-setup-script found; not modifying."
    else
      # Otherwise, add the greeter-setup-script right below the [Seat:*] line if present
      if grep -Eq '^[[:space:]]*\[Seat:\*\][[:space:]]*$' "$FILE"; then
        echo "[lightdm] Inserting greeter-setup-script below [Seat:*] section header."
        sudo sed -i '/^[[:space:]]*\[Seat:\*\][[:space:]]*$/a greeter-setup-script=/usr/bin/numlockx on' "$FILE"
      else
        # Fallback: if [Seat:*] is not found, append a new section at the end
        echo "[lightdm] [Seat:*] section not found; appending a new section at end of file."
        sudo bash -c 'printf "\n[Seat:*]\n%s\n" "greeter-setup-script=/usr/bin/numlockx on" >> /etc/lightdm/lightdm.conf'
      fi
    fi
  else
    echo "/etc/lightdm/lightdm.conf not found, skipping NumLock configuration"
  fi

  # Also configure GTK greeter: set "numlock = on" within the [greeter] section
  GTK_CONF="/etc/lightdm/lightdm-gtk-greeter.conf"
  if [[ -f "$GTK_CONF" ]]; then
    echo "[lightdm] Configuring numlock = on in lightdm-gtk-greeter.conf"

    # Check if an uncommented numlock setting already exists within the [greeter] section
    if awk '
      BEGIN { in_g=0; found=0 }
      /^[[:space:]]*\[/ {
        # enter a section; track if it is [greeter]
        if ($0 ~ /^[[:space:]]*\[greeter\][[:space:]]*$/) in_g=1; else in_g=0
      }
      in_g && $0 ~ /^[[:space:]]*numlock[[:space:]]*=/ { found=1 }
      END { exit found ? 0 : 1 }
    ' "$GTK_CONF"; then
      echo "[lightdm] Existing numlock setting in [greeter]; not modifying."
    else
      if grep -Eq '^[[:space:]]*\[greeter\][[:space:]]*$' "$GTK_CONF"; then
        echo "[lightdm] Inserting 'numlock = on' below [greeter] section header."
        sudo sed -i '/^[[:space:]]*\[greeter\][[:space:]]*$/a numlock = on' "$GTK_CONF"
      else
        echo "[lightdm] [greeter] section not found; appending a new section at end of file."
        sudo bash -c 'printf "\n[greeter]\nnumlock = on\n" >> /etc/lightdm/lightdm-gtk-greeter.conf'
      fi
    fi
  else
    echo "[lightdm] $GTK_CONF not found; skipping GTK greeter numlock configuration"
  fi
}

snapper() {
  echo "[snapper] Configure snapper for Btrfs snapshots"

  # Create a snapper config for the root filesystem
  if sudo snapper list | grep -q "^root[[:space:]]"; then
    echo "[snapper] Snapper config for root already exists"
  else
    echo "[snapper] Creating snapper config for root"
    sudo snapper -c root create-config /
  fi

  # Set up automatic snapshots via systemd timers
  echo "[snapper] Enabling snapper-timeline.timer and snapper-cleanup.timer"
  sudo systemctl enable --now snapper-timeline.timer
  sudo systemctl enable --now snapper-cleanup.timer
}

usage() {
  cat <<EOF
Usage: $0 [-s "step1,step2" | -s "name1,name2"] [-l]

Options:
  -s, --steps   Comma-separated list of steps to run. Accepts either descriptive names or (deprecated) numbers.
                Steps run in the default order; duplicates are ignored.
                Examples: -s "dnf_up,rpm_fusion" or -s "2,3"
  -l, --list    List all available steps in order.
  -h, --help    Show this help message.

Available steps (in order):
$(
  i=1
  for name in "${ALL_STEPS[@]}"; do
    printf "  %2d) %s\n" "$i" "$name"
    ((i++))
  done
)
EOF
}

# Parse args
STEPS_ARG=""
LIST_ONLY=false
while [[ $# > 0 ]]; do
  case "$1" in
    -s|--steps)
      if [[ -n "${2-}" ]]; then
        STEPS_ARG="$2"
        shift 2
        continue
      else
        echo "Error: --steps requires an argument" >&2
        usage
        exit 2
      fi
      ;;
    -l|--list)
      LIST_ONLY=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$LIST_ONLY" == true ]]; then
  usage
  exit 0
fi

# Build ordered list of steps to run (names)
declare -a RUN_STEPS=()
if [[ -z "$STEPS_ARG" ]]; then
  RUN_STEPS=("${ALL_STEPS[@]}")
else
  declare -A requested=()
  IFS=',' read -ra raw <<< "$STEPS_ARG"
  for token in "${raw[@]}"; do
    # trim whitespace
    step=$(echo "$token" | xargs)
    if [[ -z "$step" ]]; then
      continue
    fi
    if [[ "$step" =~ ^[0-9]+$ ]]; then
      idx=$((10#$step))
      if (( idx < 1 || idx > ${#ALL_STEPS[@]} )); then
        echo "Invalid step number: $step" >&2
        exit 2
      fi
      name="${ALL_STEPS[$((idx-1))]}"
      requested["$name"]=1
    else
      # Validate name is in ALL_STEPS
      valid=false
      for name in "${ALL_STEPS[@]}"; do
        if [[ "$name" == "$step" ]]; then
          valid=true
          requested["$name"]=1
          break
        fi
      done
      if [[ "$valid" != true ]]; then
        echo "Invalid step name: $step" >&2
        exit 2
      fi
    fi
  done
  # Maintain default order and dedupe
  for name in "${ALL_STEPS[@]}"; do
    if [[ -n "${requested[$name]+x}" ]]; then
      RUN_STEPS+=("$name")
    fi
  done
fi

# Dispatch by name with validation
for s in "${RUN_STEPS[@]}"; do
  if declare -F "$s" > /dev/null; then
    "$s"
  else
    echo "Unknown step function: $s" >&2
    exit 3
  fi
done
