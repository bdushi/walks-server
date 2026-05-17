#!/usr/bin/env sh
set -eu

# Reload nginx periodically so it picks up renewed certs without a container restart.
while :; do
  sleep 6h
  nginx -s reload || true
done &

