#!/usr/bin/env sh
set -eu

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed (or not in PATH)." >&2
  exit 1
fi

# Some VMs require root access to the Docker socket. Prefer plain docker, fall back to sudo.
docker_cmd() { docker "$@"; }
if ! docker ps >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    docker_cmd() { sudo docker "$@"; }
  fi
fi

if [ "${1:-}" = "" ]; then
  echo "Usage: ops/scripts/remote-deploy.sh /absolute/path/to/.env"
  exit 1
fi

ENV_FILE="$1"
if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

docker_cmd compose -f "$ROOT_DIR/docker-compose.prod.yml" --env-file "$ENV_FILE" pull
docker_cmd compose -f "$ROOT_DIR/docker-compose.prod.yml" --env-file "$ENV_FILE" up -d --remove-orphans
docker_cmd image prune -f
