# TODO: Manual Setup Checklist

This repo contains Docker + Nginx HTTPS + CI/CD + optional Terraform, but there are still steps you must do yourself (mostly credentials, DNS, and cloud account setup).

## 1) Choose Your Container Registry (OCIR vs GHCR)

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
   - `OCIR_REGISTRY` (example: `fra.ocir.io`)
   - `OCIR_REPOSITORY` (example: `tenancy_namespace/walks-server`)
   - `OCIR_USERNAME` (often `tenancy_namespace/username` depending on tenancy setup)
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

## 4) VM Prereqs (If You Created the VM Manually)

Manual tasks on the VM:
1. Install Docker Engine + Docker Compose v2 plugin.
2. Open inbound ports:
   - `22` (SSH), `80` (HTTP), `443` (HTTPS)
3. Create the runtime env file:
   - `/opt/walks-server/.env` (copy from `ops/.env.example`)
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

## 6) Contentful Credentials

Manual tasks:
1. Create/manage `CONTENTFUL_SPACE_ID` and `CONTENTFUL_ACCESS_TOKEN`.
2. Keep them out of git.
3. Put them in `/opt/walks-server/.env` on the VM.

## 7) (Optional) Terraform: “No OCI Clicking”

Terraform stack: `ops/terraform`

Manual tasks on your laptop:
1. Install Terraform.
2. Configure OCI credentials (`~/.oci/config` or env vars).
3. Fill `ops/terraform/terraform.tfvars`.
4. Run:
   - `terraform init`
   - `terraform apply`

Important:
- If you use dockerized Nginx+Certbot from `ops/docker-compose.prod.yml`, keep `install_host_nginx_certbot=false` in Terraform to avoid port conflicts on `80/443`.

## Next Decision Needed

1. Which registry do you want: GHCR or OCIR?
2. If GHCR: what image name do you want (e.g. `ghcr.io/<user>/walks-server`)?
3. What is your VM SSH user: `opc` or `ubuntu`?

