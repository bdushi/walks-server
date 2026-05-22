---
name: terraform-oci
description: Use for OCI Terraform work for walks by delegating infrastructure changes to the separate walks-infra repo (source of truth).
---

# Terraform: OCI (redirect from walks-server)

This repo no longer owns Terraform infrastructure code.

## Source of truth

- Repo: `walks-infra`
- Stack path: `walks-infra/terraform`
- CI workflows: `walks-infra/.github/workflows/terraform-plan.yml` and `terraform-apply.yml`

## Standard handoff from infra to app deploy

1. Run Terraform in `walks-infra` and capture `public_ip`.
2. Set `ORACLE_HOST=<public_ip>` in `walks-server` GitHub secrets.
3. Deploy app from `walks-server` CI (`.github/workflows/deploy.yml`).

## Boundary rule

- Terraform/network/VM changes: `walks-infra`
- App image/runtime/container deploy changes: `walks-server`
