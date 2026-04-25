# Terraform: OCI Always Free VM + Network + Bootstrap

This Terraform stack can create everything end-to-end (no OCI Console clicking):

- VCN + public subnet
- Internet Gateway + route table
- Security rules (ingress 22/80/443)
- Always Free ARM instance (Ampere A1 Flex)
- Cloud-init bootstrap:
  - Docker Engine + Docker Compose v2 plugin
  - Git
  - UFW rules (allow 22/80/443)
  - Optional: host Nginx + Certbot
  - Optional: Java (only if you want to run the jar directly without Docker)
  - systemd unit that runs your compose stack on boot (only if `/opt/walks-server/.env` exists)

## Prereqs

1. Install Terraform.
2. Configure OCI credentials for the Terraform `oci` provider (environment variables or `~/.oci/config`).
3. Have an SSH public key ready (to access the VM).

## Quick Start

```sh
cd ops/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

After apply:

1. SSH into the instance using the printed public IP.
2. Create `/opt/walks-server/.env`:
   - Either copy from `/opt/walks-server/.env.example` (created by cloud-init)
   - Or copy from `../.env.example` in this repo
3. Upload `ops/` (or let GitHub Actions do it) into `/opt/walks-server/ops`.
4. Run first-time HTTPS issuance (if you use the dockerized Nginx+Certbot stack):
   ```sh
   cd /opt/walks-server/ops
   ./scripts/init-letsencrypt.sh /opt/walks-server/.env
   ```

Then start the stack (or reboot and let systemd start it once `ops/` + `.env` exist):

```sh
cd /opt/walks-server/ops
./scripts/remote-deploy.sh /opt/walks-server/.env
```

## Notes / Tradeoffs

- This stack uses Ubuntu images by default.
- Choose one HTTPS approach:
  - Recommended: dockerized Nginx+Certbot (this repo’s `ops/docker-compose.prod.yml`)
  - Optional: host Nginx+Certbot (`install_host_nginx_certbot=true`) but then you must NOT run the dockerized `nginx` service on ports 80/443.
