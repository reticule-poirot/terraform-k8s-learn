locals {
  # Single source of truth for every container image tag in the stack.
  # Bump one line, run `terraform plan`, review, apply. Crossing a major
  # version (e.g. postgres 15 -> 18) means reading the upstream upgrade notes
  # first and recording what you checked in the PR — see AGENTS.md.
  images = {
    postgres   = "18-alpine"  # postgres:<tag>                — PGDATA pinned in the module (see postgresql/main.tf)
    redis      = "8.8-alpine" # redis:<tag>                  — 8.x wire-compatible; AOF/RDB forward-compatible
    netbox     = "v3.7.2"     # netboxcommunity/netbox:<tag>  — 4.x = Django 5 / GraphQL rewrite
    gitea      = "1.20.4"     # gitea/gitea:<tag>
    prometheus = "v3.14.0"    # prom/prometheus:<tag>         — no CLI flags/PromQL rules in use
    busybox    = "1.38.0"     # busybox:<tag>                 — netbox init container
  }
}
