# Oracle Cloud (OCI) Deployment: Docker + Nginx (HTTPS) + CI/CD

This repo ships a production `docker compose` stack that runs:

- `app` (Spring Boot on `8080`, internal only)
- `nginx` (public `80/443`, reverse proxy)
- `certbot` (Let’s Encrypt renewal loop)

The nginx config is generated from `ops/nginx/templates/walks.conf.template` at container start (via `envsubst`).

## 1) Provision an OCI VM

- Create an OCI Compute instance (AMD64 or ARM64).
- Open inbound ports `80` and `443` in Security Lists/NSGs.
- Point your domain `A` record to the VM public IP.
- Install Docker Engine + Docker Compose v2 on the VM.
- Ensure the deploy user can run Docker:
  - either add the user to the `docker` group, or
  - rely on `sudo docker ...` (the CI workflow uses `sudo`).

## 2) Create the server env file

The stack reads runtime config from `/opt/walks-server/.env` on the VM.

### Option A (recommended): CI creates `/opt/walks-server/.env` once

The GitHub Actions workflow creates `/opt/walks-server/.env` on the VM if it does not exist, using these GitHub Secrets:

- `WALKS_DOMAIN`
- `WALKS_CERTBOT_EMAIL`
- `WALKS_CONTENTFUL_SPACE_ID`
- `WALKS_CONTENTFUL_ACCESS_TOKEN`

### Option B: create it manually on the VM

On the VM (after `ops/` has been uploaded to `/opt/walks-server/ops`):

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

- `OCIR_REGISTRY` (example: `nrq.ocir.io` for `eu-turin-1` / Italy North)
- `OCIR_REPOSITORY` (example: `<tenancy-namespace>/walks-server`)
- `OCIR_USERNAME` (must be `<tenancy-namespace>/<user>`)
- `OCIR_PASSWORD` (OCI Auth Token)
- `ORACLE_HOST` (VM public IP or DNS)
- `ORACLE_USER` (SSH user, e.g. `ubuntu`)
- `ORACLE_SSH_PRIVATE_KEY` (private key contents for SSH)
- `WALKS_DOMAIN` (example: `api.example.com`)
- `WALKS_CERTBOT_EMAIL` (example: `admin@example.com`)
- `WALKS_CONTENTFUL_SPACE_ID`
- `WALKS_CONTENTFUL_ACCESS_TOKEN`

Notes:

- The OCIR "tenancy namespace" used in `OCIR_USERNAME` and `OCIR_REPOSITORY` is often **not** the same as your tenancy display name.
- If you see an error like `Tenant with namespace ... not authorized or not found`, the namespace prefix is usually wrong, or `OCIR_REGISTRY` is pointing at the wrong region.

On push to `main`, the workflow:

1. Builds and pushes a multi-arch image (`linux/amd64` + `linux/arm64`) to OCIR.
2. Uploads `ops/` to `/opt/walks-server/ops` on the VM (without deleting `ops/data/`).
3. Pulls and restarts the stack with `APP_TAG=$GITHUB_SHA`.

## 5) Verify + Troubleshoot

On the VM:

```sh
cd /opt/walks-server/ops
sudo docker compose -f docker-compose.prod.yml --env-file /opt/walks-server/.env ps
```

Common issues:

- HTTP works but you see "Welcome to nginx!": nginx is serving the stock default config, not the rendered template.
  - Ensure `/opt/walks-server/ops/nginx/templates/walks.conf.template` exists on the VM.
  - Ensure `/opt/walks-server/ops/nginx/templates/default.conf.template` is NOT present (legacy file name that won't override nginx's baked-in default).
  - Then:
    ```sh
    sudo docker compose -f docker-compose.prod.yml --env-file /opt/walks-server/.env up -d --force-recreate nginx
    ```
- HTTPS connection refused: port `443` is blocked in OCI NSG/Security List, or the stack is not bound to 443.
  - Check listeners:
    ```sh
    sudo ss -lntp | egrep ':80|:443' || true
    ```
- HTTPS handshake errors / certificate mismatch: you are browsing by IP instead of the hostname in `DOMAIN`, or you have not run the one-time issuance yet.
  - Run:
    ```sh
    sudo /opt/walks-server/ops/scripts/init-letsencrypt.sh /opt/walks-server/.env
    ```
