#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/gitea-$STAMP.tar.gz"
WAS_RUNNING=0

cd "$ROOT_DIR"
command -v podman >/dev/null || { printf 'Error: podman is required\n' >&2; exit 1; }
mkdir -p "$BACKUP_DIR"

if podman container exists gitea 2>/dev/null \
  && [[ "$(podman inspect --format '{{.State.Running}}' gitea)" == "true" ]]; then
  WAS_RUNNING=1
  printf 'Stopping Gitea for a consistent backup...\n'
  podman compose down
fi

restart_if_needed() {
  local exit_code=$?
  if (( WAS_RUNNING )); then
    printf 'Restarting Gitea...\n'
    podman compose up -d || {
      printf 'Error: backup finished, but Gitea could not be restarted.\n' >&2
      exit_code=1
    }
  fi
  exit "$exit_code"
}
trap restart_if_needed EXIT

printf 'Creating backup: %s\n' "$BACKUP_FILE"
tar -czf "$BACKUP_FILE" data config compose.yaml

printf 'Backup complete: %s\n' "$BACKUP_FILE"
