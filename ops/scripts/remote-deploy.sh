#!/usr/bin/env sh
set -eu

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

docker compose -f "$ROOT_DIR/docker-compose.prod.yml" --env-file "$ENV_FILE" pull
docker compose -f "$ROOT_DIR/docker-compose.prod.yml" --env-file "$ENV_FILE" up -d --remove-orphans
docker image prune -f
