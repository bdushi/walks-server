# walks-server: Contentful GraphQL Proxy

Spring Boot (Kotlin) middleware that sits between your client and Contentful GraphQL, providing:

- Caching (Caffeine in-memory, configurable TTLs)
- A simplified GraphQL schema (flattens `sys { id }`, removes locale args, etc.)
- GraphiQL UI for testing
- Cache management endpoints
- Actuator health/metrics

## Architecture

```
Client ──► Spring Boot Proxy ──► Contentful GraphQL API
              │
              └── Caffeine Cache (in-memory, per query type)
```

## Endpoints

- GraphQL: `POST /graphql`
- GraphiQL: `GET /graphiql`
- Cache admin:
  - `GET /admin/cache`
  - `DELETE /admin/cache`
  - `DELETE /admin/cache/{name}`
  - `DELETE /admin/cache/{name}/{key}`
- Health: `GET /actuator/health`

## Configuration

Environment variables (see `src/main/resources/application.yml`):

```sh
export CONTENTFUL_SPACE_ID=your_space_id
export CONTENTFUL_ACCESS_TOKEN=your_access_token
export CONTENTFUL_ENVIRONMENT=master          # optional, default: master
export CONTENTFUL_DEFAULT_LOCALE=en-US        # optional, default: en-US
```

Alternative for local runs: use either project-root `.env` or `ops/.env` (you already have `ops/.env.example`).  
`application.yml` imports both locations automatically via `spring.config.import`.

## Local Development (Gradle)

Run:

```sh
./gradlew bootRun
```

App starts on `http://localhost:8080`.

Build a runnable jar:

```sh
./gradlew bootJar
java -jar build/libs/*.jar
```

## Docker

This repo includes a `Dockerfile` that builds and runs the Spring Boot fat jar.

Build:

```sh
docker build -t walks-server:local .
```

Run:

```sh
docker run --rm -p 8080:8080 \
  -e CONTENTFUL_SPACE_ID=... \
  -e CONTENTFUL_ACCESS_TOKEN=... \
  walks-server:local
```

## Production: OCI VM + Docker Compose + Nginx (HTTPS)

Production stack lives in `ops/`:

- `ops/docker-compose.prod.yml`: `app` + `nginx` (80/443) + `certbot` (Let’s Encrypt renewal)
- `ops/nginx/templates/walks.conf.template`: reverse proxy to `app:8080` (rendered by nginx image via `envsubst`)

On the VM:

1. Create `/opt/walks-server/.env`:
   - Option A (recommended): let CI create it from GitHub Secrets (see `ops/README.md`).
   - Option B: copy from `/opt/walks-server/ops/.env.example` and set `DOMAIN`, `CERTBOT_EMAIL`, `CONTENTFUL_*`.
2. Upload `ops/` to `/opt/walks-server/ops` (CI does this automatically).
3. One-time HTTPS issuance (required to get a real cert for port 443):
   ```sh
   cd /opt/walks-server/ops
   chmod +x scripts/*.sh
   ./scripts/init-letsencrypt.sh /opt/walks-server/.env
   ```
4. Deploy/update:
   ```sh
   ./scripts/remote-deploy.sh /opt/walks-server/.env
   ```

More detail: `ops/README.md`.

## CI/CD (GitHub Actions -> OCIR -> OCI VM)

Workflow: `.github/workflows/deploy.yml`

On each push to `main`, it:

1. Builds and pushes a multi-arch image to OCIR.
2. Uploads `ops/` to `/opt/walks-server/ops` on the VM.
3. Pulls and restarts the compose stack with `APP_TAG=$GITHUB_SHA`.

Required GitHub secrets are listed in `ops/README.md`.

## Terraform (No OCI Console Clicking)

Terraform stack: `ops/terraform`

It can provision:

- Always Free ARM VM (`VM.Standard.A1.Flex`)
- VCN + subnet + internet gateway + routes + security rules (22/80/443)
- Cloud-init bootstrap: Docker/Compose/Git/UFW (+ optional host nginx/certbot, optional Java)

See `ops/terraform/README.md`.

## Codex Skills (Optional)

This repo includes repo-local Codex skills under `codex-skills/` (so you can reuse the same workflows while working in this project):

- `oci-deploy`
- `terraform-oci`
- `release-checks`

If you want these installed into your Codex skills directory, tell me what your Codex setup expects (or paste your preferred skills location) and I’ll wire up an install command/flow.
