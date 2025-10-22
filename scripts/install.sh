#!/usr/bin/env bash

JETBRAINS_MONO_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
INTER_FONT_URL="https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip"
OH_MY_ZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

set -euo pipefail

# Default, ordered list of descriptive step names
ALL_STEPS=(
  scripts_permission
  dnf_up
  rpm_fusion
  copr
  dnf_install
  flathub
  vscode
  oh_my_zsh
  default_zsh
  jetbrains_mono_font
  inter_font
  gsettings_theme
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scripts_permission() {
  echo "[scripts_permission] Add run permission to scripts"

  STOW_DIR="$SCRIPT_DIR/../stow"

  chmod +x "$SCRIPT_DIR/secure-boot-key.sh"
  chmod +x "$SCRIPT_DIR/nvidia-drivers.sh"
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
  PKG_FILE="$SCRIPT_DIR/../packages/dnf.txt"

  if [[ ! -f "$PKG_FILE" ]]; then
    echo "Package list not found: $PKG_FILE" >&2
    exit 1
  fi

  mapfile -t packages < <(grep -vE '^\s*($|#)' "$PKG_FILE")

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

vscode() {
  echo "[vscode] Add VS Code repository and install Code"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
  echo "[vscode] Install VS Code"
  sudo dnf check-update || true
  sudo dnf in -y code
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
