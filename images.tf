locals {
  # Single source of truth for every container image tag in the stack.
  # Bump one line, run `terraform plan`, review, apply. Crossing a major
  # version (e.g. postgres 15 -> 18) means reading the upstream upgrade notes
  # first and recording what you checked in the PR — see AGENTS.md.
  images = {
    postgres   = "15-alpine" # postgres:<tag>                — >= 18 moves PGDATA
    redis      = "7-alpine"  # redis:<tag>                   — 8 / valkey relicensing
    netbox     = "v3.7.2"    # netboxcommunity/netbox:<tag>  — 4.x = Django 5 / GraphQL rewrite
    gitea      = "1.20.4"    # gitea/gitea:<tag>
    prometheus = "v2.47.0"   # prom/prometheus:<tag>         — 3.x PromQL / flag changes
    busybox    = "1.36.1"    # busybox:<tag>                 — netbox init container
  }
}
