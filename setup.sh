#!/bin/bash
set -e
export NONINTERACTIVE=1

OS="$(uname -s)"
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

PACKAGES=(zsh git curl file)

if [ "$OS" = "Darwin" ]; then
    if ! xcode-select -p >/dev/null 2>&1; then
        xcode-select --install
        echo "Waiting for Command Line Tools install to finish..."
        until xcode-select -p >/dev/null 2>&1; do sleep 5; done
    fi
else
    if command -v apt-get >/dev/null 2>&1; then
        $SUDO env DEBIAN_FRONTEND=noninteractive apt-get update
        $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            build-essential procps "${PACKAGES[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf group install -y development-tools
        $SUDO dnf install -y procps-ng gcc "${PACKAGES[@]}"
    else
        echo "no supported package manager found" >&2
        exit 1
    fi

    ZSH_PATH="$(command -v zsh)"
    LOGIN_USER="$(id -un)"
    # getent is glibc-only; an empty result just means we re-run chsh.
    CURRENT_SHELL="$(getent passwd "$LOGIN_USER" 2>/dev/null | cut -d: -f7)"
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        $SUDO chsh -s "$ZSH_PATH" "$LOGIN_USER"
    fi
fi


# Homebrew (mac + linux)
command -v brew >/dev/null 2>&1 || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
for brew_path in "/opt/homebrew/bin/brew" "/home/linuxbrew/.linuxbrew/bin/brew" "/usr/local/bin/brew"; do
    if [ -x "$brew_path" ]; then
        eval "$("$brew_path" shellenv)"
        break
    fi
done

brew install --no-ask chezmoi
chezmoi init --apply baberabb
