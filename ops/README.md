# Oracle Cloud (OCI) Deployment: Docker + Nginx (HTTPS) + CI/CD

This repo ships a production `docker compose` stack that runs:

- `app` (Spring Boot on `8080`, internal only)
- `nginx` (public `80/443`, reverse proxy)
- `certbot` (Let’s Encrypt renewal loop)

## 1) Provision an OCI VM

- Create an OCI Compute instance (AMD64 or ARM64).
- Open inbound ports `80` and `443` in Security Lists/NSGs.
- Point your domain `A` record to the VM public IP.
- Install Docker Engine + Docker Compose v2 on the VM.

## 2) Create the server env file

On the VM:

```sh
sudo mkdir -p /opt/walks-server
sudo cp /opt/walks-server/ops/.env.example /opt/walks-server/.env
sudo nano /opt/walks-server/.env
```

You must set at least `DOMAIN`, `CERTBOT_EMAIL`, `CONTENTFUL_SPACE_ID`, `CONTENTFUL_ACCESS_TOKEN`.

## 3) First HTTPS issuance (one-time)

After the stack has been uploaded to `/opt/walks-server/ops`:

```sh
cd /opt/walks-server/ops
chmod +x scripts/*.sh
./scripts/init-letsencrypt.sh /opt/walks-server/.env
```

## 4) CI/CD (GitHub Actions)

Workflow: `.github/workflows/deploy.yml`

Required GitHub secrets:

- `OCIR_REGISTRY` (example: `fra.ocir.io`)
- `OCIR_REPOSITORY` (example: `tenancy_namespace/walks-server`)
- `OCIR_USERNAME` (OCIR username format per your tenancy, often `tenancy_namespace/username`)
- `OCIR_PASSWORD` (OCI Auth Token)
- `ORACLE_HOST` (VM public IP or DNS)
- `ORACLE_USER` (SSH user, e.g. `opc`)
- `ORACLE_SSH_PRIVATE_KEY` (private key contents for SSH)

On push to `main`, the workflow:

1. Builds and pushes a multi-arch image (`linux/amd64` + `linux/arm64`) to OCIR.
2. Uploads `ops/` to `/opt/walks-server/ops` on the VM (without deleting `ops/data/`).
3. Pulls and restarts the stack with `APP_TAG=$GITHUB_SHA`.
