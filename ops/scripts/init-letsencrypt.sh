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
  echo "Usage: ops/scripts/init-letsencrypt.sh /absolute/path/to/.env"
  exit 1
fi

ENV_FILE="$1"
if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

if [ "${DOMAIN:-}" = "" ] || [ "${CERTBOT_EMAIL:-}" = "" ]; then
  echo "Missing DOMAIN or CERTBOT_EMAIL in $ENV_FILE"
  exit 1
fi

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

LE_DIR="$ROOT_DIR/data/letsencrypt"
WEBROOT_DIR="$ROOT_DIR/data/certbot-www"

mkdir -p "$LE_DIR" "$WEBROOT_DIR"

echo "Creating a temporary self-signed cert so nginx can start..."
docker_cmd run --rm -v "$LE_DIR:/etc/letsencrypt" alpine:3.20 sh -c "
  set -eu
  apk add --no-cache openssl >/dev/null
  mkdir -p /etc/letsencrypt/live/$DOMAIN
  if [ ! -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ] || [ ! -f /etc/letsencrypt/live/$DOMAIN/privkey.pem ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
      -keyout /etc/letsencrypt/live/$DOMAIN/privkey.pem \
      -out /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
      -subj /CN=$DOMAIN >/dev/null 2>&1
  fi
"

echo "Starting nginx to answer ACME challenges..."
docker_cmd compose -f "$ROOT_DIR/docker-compose.prod.yml" --env-file "$ENV_FILE" up -d nginx

echo "Requesting certificate for $DOMAIN..."
docker_cmd compose -f "$ROOT_DIR/docker-compose.prod.yml" --env-file "$ENV_FILE" run --rm certbot \
  certonly --webroot -w /var/www/certbot \
  -d "$DOMAIN" \
  --email "$CERTBOT_EMAIL" \
  --agree-tos --no-eff-email

echo "Reloading nginx with HTTPS..."
docker_cmd compose -f "$ROOT_DIR/docker-compose.prod.yml" --env-file "$ENV_FILE" up -d --force-recreate nginx

echo "Certificate ready."
