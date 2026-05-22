# TODO: Manual Setup Checklist

This repo contains Docker + Nginx HTTPS + CI/CD for app deployment, but there are still steps you must do yourself (mostly credentials, DNS, and cloud account setup).

## 1) Choose Your Container Registry (OCIR vs GHCR)

This repo is currently intended to use **OCIR (Oracle Container Registry)** for image pushes/pulls. The **GHCR** notes below are kept as an alternative if you decide to switch registries later.

### Option A: GHCR (GitHub Container Registry) (recommended for simplicity)

Manual tasks:
1. Pick the image name, for example: `ghcr.io/<your-github-org-or-user>/walks-server`.
2. Create a GitHub Personal Access Token (PAT) for the VM to pull images:
   - scope: `read:packages`
   - plus `repo` if the package is private and GitHub requires it for access
3. On the VM, login so Docker can pull:
   - `docker login ghcr.io -u <github-user> -p <PAT>`
4. For CI image pushes, create another PAT (or reuse one) with:
   - `write:packages` (and `repo` if required)
5. Update the CI/CD workflow secrets/vars accordingly (see section 3).

Notes:
- If the GHCR package is public, the VM may be able to pull without auth.
- If private, the VM must `docker login` using a PAT. GitHub Actions’ `GITHUB_TOKEN` does not exist on your VM.

### Option B: OCIR (Oracle Container Registry)

Manual tasks:
1. Create an OCI “Auth Token” for your OCI user (used as the Docker password).
2. Populate GitHub secrets for:
   - `OCIR_REGISTRY` (example: `nrq.ocir.io` for `eu-turin-1` / Italy North)
   - `OCIR_REPOSITORY` (example: `namespace/walks-server`)
   - `OCIR_USERNAME` (OCIR username format per your tenancy, often `brunodushi/username`)
   - `OCIR_PASSWORD` (OCI Auth Token)
3. Ensure the VM can `docker login` to OCIR.

Cost note:
- OCI “Always Free” covers certain compute/network resources; registry storage/egress may still cost money depending on usage/region/account. If you want to minimize surprise costs, use GHCR.

## 2) DNS (Required for HTTPS)

Manual tasks:
1. Own a domain (or use an existing one).
2. Create an `A` record:
   - `api.yourdomain.com` -> your VM public IP
3. Wait for DNS propagation before running Let’s Encrypt.

For your domain:
- Pick the API hostname you want to serve HTTPS on (recommended): `api.highalbania.al`
- Create:
  - `A` record: `api.highalbania.al` -> `<your OCI VM public IPv4>`
- Then wait until:
  - `dig +short api.highalbania.al` returns your VM IP (or use an online DNS checker).

## 3) GitHub Actions Secrets (CI/CD)

Workflow file: `.github/workflows/deploy.yml`

Manual tasks:
1. Add SSH deploy secrets:
   - `ORACLE_HOST` (VM public IP or DNS)
   - `ORACLE_USER` (e.g. `opc` or `ubuntu`)
   - `ORACLE_SSH_PRIVATE_KEY` (private key contents)
2. Add registry secrets depending on your choice:

If using GHCR:
- `REGISTRY` = `ghcr.io`
- `IMAGE_REPO` = `<org-or-user>/walks-server`
- `REGISTRY_USERNAME` = `<github-user>`
- `REGISTRY_PASSWORD` = `<PAT with write:packages>`

If using OCIR:
- `OCIR_REGISTRY`, `OCIR_REPOSITORY`, `OCIR_USERNAME`, `OCIR_PASSWORD`
- App/runtime secrets used to create `/opt/walks-server/.env` on the VM (one-time):
  - `WALKS_DOMAIN`
  - `WALKS_CERTBOT_EMAIL`
  - `WALKS_CONTENTFUL_GRAPHQL_URL` (optional; defaults to Contentful GraphQL base URL)
  - `WALKS_CONTENTFUL_SPACE_ID`
  - `WALKS_CONTENTFUL_ACCESS_TOKEN`

## 4) VM Prereqs (If You Created the VM Manually)

Manual tasks on the VM:
1. Install Docker Engine + Docker Compose v2 plugin.
2. Open inbound ports:
   - `22` (SSH), `80` (HTTP), `443` (HTTPS)
3. Create the runtime env file (only if you are not using the CI one-time creation step):
   - `/opt/walks-server/.env` (copy from `/opt/walks-server/ops/.env.example` after `ops/` is uploaded)
   - set at least: `DOMAIN`, `CERTBOT_EMAIL`, `CONTENTFUL_SPACE_ID`, `CONTENTFUL_ACCESS_TOKEN`
4. Upload `ops/` to:
   - `/opt/walks-server/ops`

## 5) First-Time HTTPS Issuance (One-time per domain)

Manual tasks on the VM:
```sh
cd /opt/walks-server/ops
chmod +x scripts/*.sh
./scripts/init-letsencrypt.sh /opt/walks-server/.env
```

If this fails, it’s usually one of:
- DNS not pointing to the VM yet, or
- port `80` blocked, or
- another service already bound to `80/443`.

If HTTP works but you see "Welcome to nginx!", the nginx container is serving its stock default config.
Fix: make sure the VM has the latest `ops/nginx/templates/walks.conf.template` and recreate nginx:

```sh
cd /opt/walks-server/ops
sudo docker compose -f docker-compose.prod.yml --env-file /opt/walks-server/.env up -d --force-recreate nginx
```

## 6) Contentful Credentials

Manual tasks:
1. Create/manage `CONTENTFUL_SPACE_ID` and `CONTENTFUL_ACCESS_TOKEN`.
2. Keep them out of git.
3. Put them in `/opt/walks-server/.env` on the VM.
4. Optional override: set `CONTENTFUL_GRAPHQL_URL` (default is `https://graphql.contentful.com/content/v1/spaces/`).

## 7) Infrastructure Source of Truth: `walks-infra`

Terraform ownership moved to the `walks-infra` repo (stack path: `walks-infra/terraform`).

Manual tasks:
1. Configure and run infra from `walks-infra` (prefer its Terraform Plan/Apply GitHub workflows).
2. Use the resulting VM `public_ip` output as `ORACLE_HOST` in this repo’s GitHub secrets.
3. Keep host-level nginx/certbot disabled in infra when using this repo’s dockerized nginx/certbot stack.

## Next Decision Needed

Selected choices:
- Registry: **OCIR**
- VM SSH user: `ubuntu`

Note on “walks-dev” vs “walks-prod”:
- Prefer using a single repository name (e.g. `brunodushi/walks-server`) and distinguish environments via image tags (`:dev`, `:prod`) and/or separate deploy targets.

## What You Should Do Next (Given You Now Own `highalbania.al`)

1. DNS:
   - Create `A` record `api.highalbania.al` -> `<VM public IP>`.
2. VM env file:
   - On the VM, create/update `/opt/walks-server/.env` from `ops/.env.example` and set:
     - `DOMAIN=api.highalbania.al`
     - `CERTBOT_EMAIL=<your email>`
     - `CONTENTFUL_SPACE_ID=...`
     - `CONTENTFUL_ACCESS_TOKEN=...`
3. GitHub secrets:
   - Set the secrets listed in section 3 (OCIR + SSH).
4. First HTTPS issuance:
   - SSH to the VM and run the `init-letsencrypt.sh` command in section 5.
5. First deploy:
   - Push to `main` (or re-run the last workflow) and confirm:
     - `https://api.highalbania.al/actuator/health` returns `UP` (or check the VM logs via `docker compose logs -f`).
