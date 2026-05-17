#!/usr/bin/env sh
set -eu

# The nginx image ships with /etc/nginx/conf.d/default.conf (static "Welcome to nginx!").
# Remove it so the rendered template config is the only active server config.
rm -f /etc/nginx/conf.d/default.conf

