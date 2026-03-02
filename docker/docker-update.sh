#!/bin/bash
################################################################
# docker-update.sh — post-initial-setup Docker rebuild wrapper.
# Builds openclaw:local (base) then overlays Dockerfile.local (custom tools/skills).
# Requires docker-setup.sh to have been run once already for initial setup.
# Use this script instead of docker-setup.sh to:
# --build:  rebuild both image layers and restart gateway (no git pull).
# --update: git pull; if docker-setup.sh changed run it; always rebuild custom layer.
# 02/2026 Created: HighDesertHacker - https://github.com/highdeserthacker
################################################################
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="$ROOT_DIR/docker-setup.sh"
DOCKERFILE_LOCAL="$ROOT_DIR/Dockerfile.local"

usage() {
  echo "Usage: $(basename "$0") --build | --update" >&2
  echo "  --build   Build base + custom image layers, restart gateway (no git pull)" >&2
  echo "  --update  git pull; run docker-setup.sh if changed; rebuild custom, restart" >&2
  exit 1
}

[[ -f "$SETUP_SCRIPT" ]] || { echo "ERROR: docker-setup.sh not found — has initial setup been run?" >&2; exit 1; }
[[ -f "$DOCKERFILE_LOCAL" ]] || { echo "ERROR: Dockerfile.local not found" >&2; exit 1; }

build_custom() {
  echo "==> Applying Dockerfile.local on top of openclaw:local"
  docker build -t openclaw:local -f "$DOCKERFILE_LOCAL" "$ROOT_DIR"
}

restart_gateway() {
  echo "==> Restarting gateway"
  (cd "$ROOT_DIR" && docker compose up -d --force-recreate openclaw-gateway)
}

# Ensure Linuxbrew is bootstrapped in the bind-mounted /home/linuxbrew.
# The skill manager requires brew to already exist — it will not install it.
# This runs after the gateway starts; the check is fast and idempotent.
ensure_brew() {
  echo "==> Checking Linuxbrew..."
  # Give the container a moment to finish starting
  sleep 3
  if (cd "$ROOT_DIR" && docker compose exec -u node openclaw-gateway \
        test -f /home/linuxbrew/.linuxbrew/bin/brew) 2>/dev/null; then
    echo "==> Linuxbrew already present — skipping bootstrap"
  else
    echo "==> Linuxbrew not found — bootstrapping into bind mount (this takes several minutes)..."
    # The bind-mounted /home/linuxbrew is owned by the host user; fix ownership
    # inside the container so the node user can write to it.
    (cd "$ROOT_DIR" && docker compose exec -u root openclaw-gateway \
      chown node:node /home/linuxbrew)
    (cd "$ROOT_DIR" && docker compose exec -u node openclaw-gateway \
      bash -c 'NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')
    echo "==> Linuxbrew bootstrapped"
  fi
}

do_build() {
  echo "==> Building base image: openclaw:local"
  docker build -t openclaw:local "$ROOT_DIR"
  build_custom
  restart_gateway
  ensure_brew
}

MODE="${1:-}"
case "$MODE" in
  --build)
    do_build
    ;;

  --update)
    HASH_BEFORE="$(sha256sum "$SETUP_SCRIPT" | awk '{print $1}')"

    echo "==> Pulling latest changes"
    git -C "$ROOT_DIR" pull

    HASH_AFTER="$(sha256sum "$SETUP_SCRIPT" | awk '{print $1}')"

    if [[ "$HASH_BEFORE" != "$HASH_AFTER" ]]; then
      echo "==> docker-setup.sh has changed — running it"
      echo "    Note: onboarding prompts will appear; step through them again"
      OPENCLAW_DOCKER_APT_PACKAGES="" "$SETUP_SCRIPT"
    else
      echo "==> docker-setup.sh unchanged — rebuilding base directly"
      docker build -t openclaw:local "$ROOT_DIR"
    fi

    # Always apply custom layer on top and restart with it
    build_custom
    restart_gateway
    ensure_brew
    ;;

  *)
    usage
    ;;
esac
