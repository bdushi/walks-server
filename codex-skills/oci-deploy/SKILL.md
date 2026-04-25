---
name: oci-deploy
description: Use for deploying this repo to an Oracle Cloud (OCI) VM using Docker, docker compose, OCIR, Nginx HTTPS (Let's Encrypt), and the repo's ops/ scripts and GitHub Actions workflow.
---

# OCI Deploy (walks-server)

## What to use in this repo

- Production compose stack: `ops/docker-compose.prod.yml`
- Env template: `ops/.env.example`
- First HTTPS issuance: `ops/scripts/init-letsencrypt.sh`
- Deploy/update: `ops/scripts/remote-deploy.sh`
- CI/CD: `.github/workflows/deploy.yml`
- Terraform provisioning: `ops/terraform`

## VM assumptions

- Ports open: `22`, `80`, `443`
- Docker Engine + Docker Compose v2 installed
- App lives at `/opt/walks-server`:
  - `/opt/walks-server/.env`
  - `/opt/walks-server/ops/` (uploaded from repo `ops/`)

## Standard deploy workflow

1. Ensure `/opt/walks-server/.env` exists and includes at least:
   - `DOMAIN`, `CERTBOT_EMAIL`, `CONTENTFUL_SPACE_ID`, `CONTENTFUL_ACCESS_TOKEN`
2. Upload/update `/opt/walks-server/ops` from the repo `ops/` (or via CI).
3. If this is the first time on this domain:
   - Run: `cd /opt/walks-server/ops && ./scripts/init-letsencrypt.sh /opt/walks-server/.env`
4. Deploy/update:
   - `cd /opt/walks-server/ops && ./scripts/remote-deploy.sh /opt/walks-server/.env`

## CI/CD requirements (GitHub Actions)

Populate these repo secrets (see `ops/README.md` for examples):

- `OCIR_REGISTRY`, `OCIR_REPOSITORY`, `OCIR_USERNAME`, `OCIR_PASSWORD`
- `ORACLE_HOST`, `ORACLE_USER`, `ORACLE_SSH_PRIVATE_KEY`

## Common failure modes

- Nginx can’t bind `80/443`: another process (host nginx) is already using the ports.
- Let’s Encrypt issuance fails: DNS A record not pointing at the VM, or `80` blocked.
- App not reachable: `DOMAIN` mismatch in `.env`, or security rules missing, or compose not running.
