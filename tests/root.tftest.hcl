# Plan-level checks for the root module: feature-flag plumbing and outputs.
# No cluster required.

# Override the real provider so the fake credentials below are not PEM-validated.
provider "kubernetes" {}

variables {
  host                   = "https://localhost:6443"
  client_certificate     = base64encode("dummy")
  client_key             = base64encode("dummy")
  cluster_ca_certificate = base64encode("dummy")
  netbox_password        = "test-password"
  gitea_db_password      = "test-password"
  redis_password         = "test-password"
  redis_cache_password   = "test-password"
  secret_key             = "0123456789012345678901234567890123456789012345678901"
  netbox_tls_cert        = base64encode("dummy-cert")
  netbox_tls_key         = base64encode("dummy-key")
}

run "core_stack_only" {
  command = plan

  variables {
    enable_gitea      = false
    enable_prometheus = false
  }

  assert {
    condition     = output.netbox_url == "https://netbox.example.local"
    error_message = "netbox_url output must be derived from the module fqdn"
  }

  assert {
    condition     = output.gitea_enabled == false
    error_message = "gitea_enabled must reflect enable_gitea"
  }

  assert {
    condition     = output.prometheus_enabled == false
    error_message = "prometheus_enabled must reflect enable_prometheus"
  }
}

run "all_features_plan_clean" {
  command = plan

  variables {
    enable_gitea      = true
    enable_prometheus = true
  }

  assert {
    condition     = output.gitea_enabled == true
    error_message = "gitea_enabled must be true when enable_gitea = true"
  }

  assert {
    condition     = output.prometheus_enabled == true
    error_message = "prometheus_enabled must be true when enable_prometheus = true"
  }
}
