# AGENTS.md

Guidance for AI agents (and humans) working in this repository.

## What this is

A learning project. Terraform configuration that deploys
[NetBox](https://github.com/netbox-community/netbox) (IPAM/DCIM) and its runtime
dependencies onto a **local single-node Kubernetes cluster**, using only the
`hashicorp/kubernetes` provider — no Helm, no operators. Everything is expressed
as plain Kubernetes API objects in HCL.

Priorities, in order: correct and readable HCL, small composable modules,
reproducible results.

## Repository layout

| Path | Purpose |
|------|---------|
| `infra.tf` | `terraform` settings + `kubernetes` provider configuration |
| `main.tf` | root module — wires the component modules together |
| `variables.tf` | root input variables (cluster connection + app secrets) |
| `outputs.tf` | root outputs |
| `prometheus.yml.tftpl` | scrape-config template rendered by the prometheus module |
| `terraform.tfvars` | **local, gitignored** — real secrets and cluster credentials |
| `.terraform-docs.yml` | config for generating the `README.md` doc blocks |
| `modules/postgresql/` | single-instance Postgres `StatefulSet` + hostPath `PersistentVolume` |
| `modules/redis/` | Redis `Deployment` — instantiated twice (queue broker + cache) |
| `modules/netbox/` | NetBox server + rq-worker `Deployment`, housekeeping `CronJob`, `Service`, optional TLS `Ingress` |
| `modules/gitea/` | optional Gitea `Deployment` (`enable_gitea`) |
| `modules/prometheus/` | optional Prometheus `Deployment` (`enable_prometheus`) |

The root composes: `netbox` + one `postgresql` + two `redis` instances always;
`gitea` (+ its own `postgresql`) and `prometheus` behind feature flags.

## Prerequisites

- Terraform `>= 1.16`
- A local Kubernetes cluster — Docker Desktop, `kind`, or `minikube`
- An **ingress-nginx** controller installed in that cluster (Ingress objects stay
  pending without it)
- `kubectl` with its current context pointing at that cluster
- Optional tooling (see [Toolchain](#toolchain)): `terraform-docs`, `tflint`, `trivy`

## Configuration

`terraform.tfvars` is **not committed** (gitignored). Create it locally and set
every value below:

- **Cluster connection** — `host`, and base64-encoded PEM for
  `client_certificate`, `client_key`, `cluster_ca_certificate` (these are already
  base64 inside a kubeconfig; `main.tf` `base64decode`s them).
- **App secrets** — `netbox_password`, `redis_password`, `redis_cache_password`,
  `secret_key` (**must be ≥ 50 characters**), `netbox_tls_cert`, `netbox_tls_key`,
  and `gitea_db_password` if `enable_gitea = true`.

`terraform.tfvars` is gitignored (`*.tfvars`). **Never commit it** and never paste
its contents into a PR, an issue, or an external service.

## State & backend

Local backend only — state lives in `terraform.tfstate` (gitignored). There is
**no remote backend**; do not add a `backend {}` block.

## Core workflow

| Task | Command |
|------|---------|
| Format | `terraform fmt -recursive` |
| Validate (no cluster needed) | `terraform validate` |
| Plan | `terraform plan` |
| Apply | `terraform apply` |
| Regenerate docs | `docker run --rm -v "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:latest -c /terraform-docs/.terraform-docs.yml /terraform-docs` |
| Lint | `tflint --recursive` |
| Security scan | `trivy config .` |

## Definition of done

Before treating a change as complete:

1. `terraform fmt -recursive` — clean
2. `terraform validate` — passes
3. `terraform plan` — reviewed; the diff contains **only** what you intended
   (watch for resource replacements and unexpected `-/+`)
4. `terraform-docs` regenerated if any module's inputs, outputs, or resources
   changed
5. Tests pass (`tests/*.tftest.hcl`, once present)

Report failures honestly — if `plan` shows a replacement you didn't expect, or a
step was skipped, say so.

## Conventions

### Module structure

Each module contains: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`,
`README.md`. The `README.md` doc block between `<!-- BEGIN_TF_DOCS -->` and
`<!-- END_TF_DOCS -->` is generated — do not hand-edit it.

### Provider & resource names

- Provider: `hashicorp/kubernetes`, pinned `~> 3.2` in every module's
  `versions.tf`.
- Use the **version-suffixed** resource type names — `kubernetes_deployment_v1`,
  `kubernetes_service_v1`, `kubernetes_config_map_v1`, `kubernetes_secret_v1`,
  `kubernetes_stateful_set_v1`, `kubernetes_persistent_volume_v1`,
  `kubernetes_persistent_volume_claim_v1`, `kubernetes_ingress_v1`,
  `kubernetes_cron_job_v1`. The unsuffixed aliases are deprecated in provider v3.
- Kubernetes object names derive from `var.name`. Renaming an object forces
  replacement — change names deliberately and expect the churn in `plan`.

### Labels

Every workload carries the recommended labels:

```hcl
"app.kubernetes.io/name"       = var.name
"app.kubernetes.io/version"    = var.<component>_version
"app.kubernetes.io/component"  = "database" | "kvstorage" | "server" | ...
"app.kubernetes.io/managed-by" = "terraform"
```

### Secrets vs config

- Sensitive data → `kubernetes_secret_v1`, mounted as files under
  `/var/run/secrets/...`. Never put a secret in a ConfigMap or a plain env var.
- Non-secret settings → `kubernetes_config_map_v1`, injected with `env_from`.
- Any Terraform variable holding a secret sets `sensitive = true`.

### Container images & versions

- **Pin every image** — no `latest`, no floating major tags. Image versions are
  centralized (see roadmap item 3); until then they live in `main.tf` and module
  variable defaults.
- **Crossing a major version** (e.g. `postgres:15` → `18`, `netbox:v3` → `v4`):
  read the upstream release notes / upgrade guide first, and record in the PR
  which breaking changes you checked. Known landmines:
  - **postgres ≥ 18** Docker images changed the default `PGDATA` to a
    version-specific subdirectory — set `PGDATA` explicitly or data lands off the
    mounted volume.
  - **netbox 4.x** — Django 5 / Python 3.10+, GraphQL API rewritten, some model
    and field changes.
  - **prometheus 3.x** — PromQL range-selector and function renames, removed
    deprecated CLI flags, stricter config parsing.
  - **redis 8 / valkey** — relicensing; wire-compatible, but confirm the image
    name and entrypoint flags.

## Known issues / gotchas

- The `postgresql` module uses a **hostPath** `PersistentVolume` — single-node
  only. Data survives pod restarts, not node changes.
- The `netbox` Deployment has a **7-minute** create timeout (first-run database
  migrations).
- Applying the full stack from an empty state is slow and order-sensitive; if an
  apply fails partway, re-run `plan` before the next `apply` to see real drift.

## Adding a component module

1. Create `modules/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`,
   `versions.tf`, `README.md`.
2. Add a `module` block in `main.tf`; gate it behind an `enable_<name>` bool if
   it is optional.
3. Run `terraform-docs`, `terraform validate`, and add
   `tests/<name>.tftest.hcl` with `command = plan` assertions.

## Toolchain

Only `terraform` and `kubectl` are required. `terraform-docs` runs via Docker
(no local install — see [Core workflow](#core-workflow)). Install the other
optional tools with:

```sh
brew install tflint trivy pre-commit
```

## Modernization roadmap (in progress)

This repo is mid-refactor. Target state, not yet fully realized:

1. ~~**Provider v3** — migrate `2.23.0` → `~> 3.2`, rename all resources to the
   `_v1` types.~~ **Done** (provider 3.2.1). State was empty at the time of the
   rename, so no `moved {}` blocks were needed; add them if you rename a resource
   that already exists in `terraform.tfstate`.
2. **File split** — break `infra.tf` into `versions.tf` / `providers.tf`; add
   `versions.tf` to every module.
3. **Centralized image versions** — one `locals` map / `images.auto.tfvars`
   instead of scattered literals and `latest` defaults.
4. **Quality gates** — `.pre-commit-config.yaml`, `.tflint.hcl`, GitHub Actions
   CI running fmt / validate / tflint / trivy / terraform-docs.
5. **Tests** — `tests/*.tftest.hcl` plan-level assertions per module.
6. **Version bumps** — one component per PR, verified with `plan`/`apply`:
   busybox, Redis 8, PostgreSQL 18, Prometheus 3, Gitea, NetBox 4 (last).
7. **K8s hardening** — per-stack namespaces, resource requests/limits,
   `securityContext`, StatefulSet `volume_claim_template`, drop the hostPath PV.
