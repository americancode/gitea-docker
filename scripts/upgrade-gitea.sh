#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/compose.yaml"
BACKUP_DIR="$ROOT_DIR/backups"

usage() {
  printf 'Usage: %s <version-rootless>\n' "$(basename "$0")"
  printf 'Example: %s 1.25-rootless\n' "$(basename "$0")"
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

TARGET_TAG="$1"
if [[ ! "$TARGET_TAG" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?-rootless$ ]]; then
  printf 'Error: tag must look like 1.25-rootless or 1.25.4-rootless\n' >&2
  exit 2
fi

command -v podman >/dev/null || { printf 'Error: podman is required\n' >&2; exit 1; }
cd "$ROOT_DIR"

CURRENT_TAG="$(sed -nE 's|^[[:space:]]*image:[[:space:]]*docker\.io/gitea/gitea:([^[:space:]]+).*$|\1|p' "$COMPOSE_FILE" | head -n 1)"
if [[ -z "$CURRENT_TAG" ]]; then
  printf 'Error: could not find the Gitea image in %s\n' "$COMPOSE_FILE" >&2
  exit 1
fi

if [[ "$CURRENT_TAG" == "$TARGET_TAG" ]]; then
  printf 'Already configured for %s; continuing to pull the latest image for that tag.\n' "$TARGET_TAG"
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/gitea-$STAMP.tar.gz"
mkdir -p "$BACKUP_DIR"

printf 'Stopping Gitea...\n'
podman compose down

printf 'Creating backup: %s\n' "$BACKUP_FILE"
tar -czf "$BACKUP_FILE" data config compose.yaml

printf 'Changing image tag: %s -> %s\n' "$CURRENT_TAG" "$TARGET_TAG"
sed -i.bak "s|docker\.io/gitea/gitea:${CURRENT_TAG}|docker.io/gitea/gitea:${TARGET_TAG}|" "$COMPOSE_FILE"
rm -f "$COMPOSE_FILE.bak"

printf 'Pulling and starting Gitea...\n'
podman compose pull gitea
podman compose up -d

printf '\nUpgrade complete.\n'
podman compose ps
printf 'Backup retained at: %s\n' "$BACKUP_FILE"
