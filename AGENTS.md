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
| `versions.tf` | `required_version` + `required_providers` (root and every module) |
| `providers.tf` | `kubernetes` provider configuration (root only) |
| `images.tf` | `local.images` — the single source of truth for container image tags |
| `main.tf` | root module — wires the component modules together |
| `variables.tf` | root input variables (cluster connection + app secrets) |
| `outputs.tf` | root outputs |
| `prometheus.yml.tftpl` | scrape-config template rendered by the prometheus module |
| `terraform.tfvars` | **local, gitignored** — real secrets and cluster credentials |
| `.terraform-docs.yml` | config for generating the `README.md` doc blocks |
| `.tflint.hcl` | tflint config (recommended preset + a few extras) |
| `scripts/check.sh` | runs every quality gate via Docker |
| `tests/*.tftest.hcl` | `terraform test` plan-level assertions (one file per module + root) |
| `modules/postgresql/` | single-instance Postgres `StatefulSet` with a `volume_claim_template` |
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
| **Run every quality gate** | `scripts/check.sh` (add `--fix` to auto-format and regenerate docs) |
| Format | `terraform fmt -recursive` |
| Validate (no cluster needed) | `terraform validate` |
| Plan | `terraform plan` |
| Apply | `terraform apply` |
| Regenerate docs | `scripts/check.sh --fix`, or the `terraform-docs` Docker run it wraps |
| Lint | `scripts/check.sh` (wraps `tflint` + `trivy` Docker images) |

`scripts/check.sh` needs only `terraform` and `docker` on PATH — the linters run
as pinned Docker images (`tflint`, `trivy`, `terraform-docs`), nothing is
installed. It runs fmt-check, `terraform validate`, `terraform test`,
`tflint --recursive` against `.tflint.hcl`, `trivy config`, and a
`terraform-docs --output-check`.

## Definition of done

Before treating a change as complete:

1. `scripts/check.sh` — passes (fmt, validate, `terraform test`, tflint, trivy,
   terraform-docs freshness). Use `--fix` first to auto-format and regenerate
   docs.
2. `terraform plan` — reviewed; the diff contains **only** what you intended
   (watch for resource replacements and unexpected `-/+`)

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

- **Pin every image** — no `latest`, no floating major tags. Every image tag
  lives in the `local.images` map in `images.tf`; module version variables have
  **no default** (the root must pass an explicit tag). Bump a version there, not
  in a module.
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

- Storage is dynamically provisioned by whatever the **default `StorageClass`**
  is (Docker Desktop: `standard`, `rancher.io/local-path`). No hand-rolled PVs.
  That class binds `WaitForFirstConsumer`, so the standalone PVCs set
  `wait_until_bound = false` — otherwise `apply` deadlocks (PVC won't bind until
  its pod schedules; the pod isn't created until the PVC resource "completes").
- On first `apply` the `netbox` pod restarts a few times (~2–4): the startup
  probe is impatient during v4 migrations, and `netbox-worker` crashes with
  `relation "core_job" does not exist` until the main container finishes
  migrating. It converges on its own — the deployment goes 2/2 in ~3 min.
- The `netbox` Deployment has a **10-minute** create timeout (first-run
  migrations + search reindex on v4).
- If an `apply` is interrupted, PVCs it created may be left **not tracked in
  state** ("... already exists" on the next apply). `kubectl delete pvc` the
  orphans (they're `Pending`/empty) and re-apply.
- **Apply-tested once** (core stack: netbox v4.6.9 + PG18 + redis 8.8, on Docker
  Desktop, 2026-08-30): comes up healthy, `plan` clean afterwards. The
  `securityContext` is deliberately conservative (`seccompProfile:
  RuntimeDefault`, `allowPrivilegeEscalation: false`, `drop: ["ALL"]` on
  redis/netbox/prometheus — not postgres/gitea). `runAsNonRoot`,
  `readOnlyRootFilesystem`, `fsGroup` are **not** set. Resource requests/limits
  are rough guesses.
- `enable_gitea = true` / `enable_prometheus = true` are still plan-only,
  never applied.

## Adding a component module

1. Create `modules/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`,
   `versions.tf`, `README.md`. Take a required `namespace` variable and set
   `metadata { namespace = var.namespace }` on every namespaced resource.
2. Add a `module` block in `main.tf` passing `namespace = local.namespace`; gate
   it behind an `enable_<name>` bool if it is optional.
3. Run `scripts/check.sh --fix`, then add `tests/<name>.tftest.hcl` with
   `command = plan` assertions.

## Toolchain

Only `terraform`, `kubectl`, and `docker` are required. The linters
(`tflint`, `trivy`, `terraform-docs`) are never installed — `scripts/check.sh`
runs them as pinned Docker images. Bump an image tag in that script to update a
linter.

## Modernization roadmap (in progress)

This repo is mid-refactor. Target state, not yet fully realized:

1. ~~**Provider v3** — migrate `2.23.0` → `~> 3.2`, rename all resources to the
   `_v1` types.~~ **Done** (provider 3.2.1). State was empty at the time of the
   rename, so no `moved {}` blocks were needed; add them if you rename a resource
   that already exists in `terraform.tfstate`.
2. ~~**File split** — break `infra.tf` into `versions.tf` / `providers.tf`; add
   `versions.tf` to every module.~~ **Done.**
3. ~~**Centralized image versions** — one `locals` map instead of scattered
   literals and `latest` defaults.~~ **Done** (`images.tf`, `local.images`).
4. ~~**Quality gates** — fmt / validate / tflint / trivy / terraform-docs.~~
   **Done** — `scripts/check.sh` + `.tflint.hcl`, all linters as pinned Docker
   images. No pre-commit, no CI service (by choice).
5. ~~**Tests** — `tests/*.tftest.hcl` plan-level assertions per module.~~
   **Done** — one file per module + `tests/root.tftest.hcl` (feature-flag
   plumbing), 12 `run` blocks, all `command = plan`. Run via `scripts/check.sh`
   or `terraform test`.
6. ~~**Version bumps** — one component per commit.~~ **Done (plan-verified,
   not apply-verified):** busybox 1.38.0, Redis 8.8, PostgreSQL 18 (PGDATA
   pinned), Prometheus v3.14.0 (template trimmed), Gitea 1.27.2, NetBox v4.6.9
   (startup probe switched from `unitd` to `granian`). Apply-test the stack
   before trusting these.
7. ~~**K8s hardening**~~ **Partly done (plan-verified only):** whole stack now
   deploys into one namespace (`var.namespace`, default `netbox`); every
   container has resource requests/limits and a conservative `securityContext`;
   postgres uses a `volume_claim_template`; the hostPath PV is gone (dynamic
   provisioning). Still open: `runAsNonRoot` / `readOnlyRootFilesystem` /
   `fsGroup`, NetworkPolicies, and an actual apply.
