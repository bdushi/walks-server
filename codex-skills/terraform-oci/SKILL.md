---
name: terraform-oci
description: Use for provisioning and managing OCI infrastructure for this repo using ops/terraform (VCN, subnet, IGW, Always Free ARM VM, security rules, cloud-init bootstrap).
---

# Terraform: OCI (walks-server)

## Location

- Terraform stack: `ops/terraform`

## Typical commands

From repo root:

```sh
cd ops/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Destroy:

```sh
terraform destroy
```

## Key variables

- `compartment_ocid`, `region`, `ssh_public_key`, `domain`
- Compute: `shape` (default `VM.Standard.A1.Flex`), `ocpus`, `memory_in_gbs`
- Optional:
  - `image_ocid` to pin a specific image (prevents unexpected instance replacement later)
  - `install_host_nginx_certbot` (not recommended if using dockerized nginx in `ops/docker-compose.prod.yml`)
  - `install_java` (only if running jar directly on host)

## Post-provision checklist on the VM

1. Create `/opt/walks-server/.env` (from `/opt/walks-server/.env.example` or `ops/.env.example`).
2. Upload repo `ops/` to `/opt/walks-server/ops` (or via CI/CD).
3. Run first-time HTTPS issuance if using dockerized nginx:
   - `cd /opt/walks-server/ops && ./scripts/init-letsencrypt.sh /opt/walks-server/.env`
