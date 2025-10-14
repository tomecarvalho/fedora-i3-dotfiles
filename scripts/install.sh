#!/usr/bin/env bash

GREENCLIP_URL="https://github.com/erebe/greenclip/releases/download/v4.2/greenclip"

set -euo pipefail

# Default: run all steps in order 1..5
ALL_STEPS=(1 2 3 4 5 6 7 8 9)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step1() {
  echo "1. Add run permission to scripts"

  STOW_DIR="$SCRIPT_DIR/../stow"

  chmod +x "$STOW_DIR/i3/.config/i3/scripts/gnome-keyring.sh"
  chmod +x "$STOW_DIR/rofi/.config/rofi/scripts/rofi-power-menu.sh"

  echo "1. Run permission added to scripts"
}

step2() {
  echo "2. Update packages"
  sudo dnf up -y --refresh
}

step3() {
  echo "3. Enable RPM Fusion Free and Nonfree"
  sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

step4() {
  echo "4. Install DNF packages"
  PKG_FILE="$SCRIPT_DIR/../packages/dnf.txt"

  if [[ ! -f "$PKG_FILE" ]]; then
    echo "Package list not found: $PKG_FILE" >&2
    exit 1
  fi

  mapfile -t packages < <(grep -vE '^\s*($|#)' "$PKG_FILE")

  echo "4. Installing ${#packages[@]} packages with dnf..."
  sudo dnf install -y "${packages[@]}"
}

step5() {
  echo "5. Enable Flathub"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

step6() {
  echo "6. Add VS Code repository"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
  echo "6. Install VS Code"
  sudo dnf check-update
  sudo dnf install -y code
}

step7() {
  echo "7. Install oh-my-zsh"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "oh-my-zsh is already installed at $HOME/.oh-my-zsh"
    return
  fi

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Remove the custom directory, because stow will replace it
  rm -rf "$HOME/.oh-my-zsh/custom"
}

step8() {
  echo "8. Install greenclip"

  if command -v greenclip &> /dev/null; then
    echo "greenclip is already installed"
    return
  fi

  # Install for all users
  GREENCLIP_PATH="/usr/bin/greenclip"
  sudo curl -L -o "$GREENCLIP_PATH" "$GREENCLIP_URL"
  sudo chmod +x "$GREENCLIP_PATH"
  echo "greenclip installed to $GREENCLIP_PATH"
}

step9() {
  echo "9. Make zsh the default shell"

  if ! command -v zsh &> /dev/null; then
    echo "zsh is not installed. Please install zsh first." >&2
    exit 1
  fi

  chsh -s "$(command -v zsh)"
}

usage() {
  cat <<EOF
Usage: $0 [-s "1,2,3"]

Options:
  -s, --steps   Comma-separated list of step numbers to run. Steps will be run sequentially in numeric order (duplicates removed). Example: -s "1,3,5"
  -h, --help    Show this help message
EOF
}

# Parse args
STEPS_ARG=""
while [[ $# -gt 0 ]]; do
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

# Build ordered list of steps to run
declare -a RUN_STEPS=()
if [[ -z "$STEPS_ARG" ]]; then
  RUN_STEPS=("${ALL_STEPS[@]}")
else
  # split on commas, allow spaces
  IFS=',' read -ra raw <<< "$STEPS_ARG"
  for token in "${raw[@]}"; do
    # trim whitespace
    step=$(echo "$token" | xargs)
    if [[ -z "$step" ]]; then
      continue
    fi
    if ! [[ "$step" =~ ^[0-9]+$ ]]; then
      echo "Invalid step: $step" >&2
      exit 2
    fi
    RUN_STEPS+=("$step")
  done
  # sort numerically and deduplicate
  if [[ ${#RUN_STEPS[@]} -gt 0 ]]; then
    IFS=$'\n' read -r -d '' -a RUN_STEPS < <(printf "%s\n" "${RUN_STEPS[@]}" | sort -n -u && printf '\0')
  fi
fi

# Dispatch
for s in "${RUN_STEPS[@]}"; do
  case "$s" in
    1) step1 ;;
    2) step2 ;;
    3) step3 ;;
    4) step4 ;;
    5) step5 ;;
    6) step6 ;;
    7) step7 ;;
    8) step8 ;;
    9) step9 ;;
    *) echo "Unknown step: $s" >&2; exit 3 ;;
  esac
done
