---
name: release-checks
description: Use for doing a fast release readiness pass for this repo (Gradle build/tests, config sanity, Docker build, and ops/ deployment sanity checks).
---

# Release Checks (walks-server)

## Local verification

- Build + tests:
  - `./gradlew test`
  - `./gradlew bootJar`
- Confirm runtime config:
  - `src/main/resources/application.yml` references the required env vars

## Docker verification (if Docker is available)

- `docker build -t walks-server:local .`

## Production sanity checks

- `.env` includes `DOMAIN`, `CERTBOT_EMAIL`, and Contentful env vars
- `ORACLE_HOST` in `walks-server` secrets matches the current `public_ip` from `walks-infra` Terraform output
- Ports open on VM: `80/443`
- No host-level nginx bound to `80/443` if using dockerized nginx
- `ops/scripts/init-letsencrypt.sh` has been run once for the domain
