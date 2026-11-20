#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================
# System Update Script
# Arch Linux / ML4W / yay
# ==========================================

readonly SCRIPT_NAME="${0##*/}"
readonly JOURNAL_RETENTION="7d"
readonly ML4W_URL="https://ml4w.com/os/stable"

UPDATE_ML4W=false

# ------------------------------------------
# Functions
# ------------------------------------------

log() {
    printf '\n\033[1;34m==> %s\033[0m\n' "$*"
}

success() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$*"
}

error() {
    printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
}

cleanup() {
    local exit_code=$?

    if (( exit_code != 0 )); then
        error "Update failed (exit code: $exit_code)."
    fi
}

trap cleanup EXIT

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  --update-ml4w    Update ML4W after system updates
  -h, --help       Show this help message
EOF
}

# ------------------------------------------
# Argument parsing
# ------------------------------------------

for arg in "$@"; do
    case "$arg" in
        --update-ml4w)
            UPDATE_ML4W=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $arg"
            usage
            exit 1
            ;;
    esac
done

# ------------------------------------------
# Dependency checks
# ------------------------------------------

for cmd in yay sudo pacman journalctl systemd-tmpfiles; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error "Required command not found: $cmd"
        exit 1
    fi
done

if ! command -v rustup >/dev/null 2>&1; then
    log "Rustup not found. Skipping Rust update."
fi

if [[ "$UPDATE_ML4W" == true ]] && ! command -v curl >/dev/null 2>&1; then
    error "curl is required for ML4W updates."
    exit 1
fi

# ------------------------------------------
# System update
# ------------------------------------------

log "Starting full system update..."

yay -Syu --noconfirm

success "System packages updated."

# ------------------------------------------
# Remove orphaned packages
# ------------------------------------------

log "Checking for orphaned packages..."

orphans=$(pacman -Qtdq || true)

if [[ -n "$orphans" ]]; then
    printf '%s\n' "$orphans"
    sudo pacman -Rns --noconfirm $orphans
    success "Orphaned packages removed."
else
    success "No orphaned packages found."
fi

# ------------------------------------------
# Package cache cleanup
# ------------------------------------------

log "Cleaning package cache..."

yay -Sc --noconfirm

success "Package cache cleaned."

# ------------------------------------------
# Journal cleanup
# ------------------------------------------

log "Cleaning system journals..."

sudo journalctl --vacuum-time="$JOURNAL_RETENTION"

success "System journals cleaned."

# ------------------------------------------
# Temporary files cleanup
# ------------------------------------------

log "Cleaning temporary files..."

sudo systemd-tmpfiles --clean

success "Temporary files cleaned."

# ------------------------------------------
# Rust update
# ------------------------------------------

if command -v rustup >/dev/null 2>&1; then
    log "Updating Rust toolchains..."
    rustup update
    success "Rust updated."
fi

# ------------------------------------------
# ML4W update
# ------------------------------------------

if [[ "$UPDATE_ML4W" == true ]]; then
    log "Updating ML4W..."

    bash <(curl -fsSL "$ML4W_URL")

    success "ML4W update completed."
fi

# ------------------------------------------
# Finished
# ------------------------------------------

log "All update tasks completed successfully!"
