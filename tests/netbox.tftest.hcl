# Plan-level checks for the netbox module. No cluster required.

provider "kubernetes" {}

variables {
  namespace            = "test-ns"
  netbox_version       = "v4.1.7"
  busybox_version      = "1.37.0"
  netbox_db_password   = "test-password"
  netbox_db_service    = "postgresql-netbox"
  redis_service        = "redis"
  redis_password       = "test-password"
  redis_cache_service  = "redis-cache"
  redis_cache_password = "test-password"
  secret_key           = "0123456789012345678901234567890123456789012345678901"
}

run "netbox_defaults" {
  command = plan

  module {
    source = "./modules/netbox"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.netbox.spec[0].template[0].spec[0].init_container[0].image == "busybox:1.37.0"
    error_message = "init container image must be busybox:<busybox_version>"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.netbox.spec[0].template[0].spec[0].container[0].image == "netboxcommunity/netbox:v4.1.7"
    error_message = "server image must be netboxcommunity/netbox:<netbox_version>"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.netbox.spec[0].template[0].spec[0].container[1].name == "netbox-worker"
    error_message = "second container must be the rq worker"
  }

  assert {
    condition     = kubernetes_service_v1.netbox_service.spec[0].port[0].port == 8080
    error_message = "service must expose port 8080"
  }

  assert {
    condition     = kubernetes_config_map_v1.netbox_env.data["ALLOWED_HOSTS"] == "netbox.example.local netbox"
    error_message = "ALLOWED_HOSTS must be '<fqdn> <name>'"
  }

  assert {
    condition     = length(kubernetes_stateful_set_v1.netbox.spec[0].volume_claim_template) == 3
    error_message = "module must define media, reports and scripts volume_claim_templates"
  }

  assert {
    condition     = length(kubernetes_ingress_v1.netbox) == 0
    error_message = "no ingress without TLS material"
  }

  assert {
    condition     = length(kubernetes_secret_v1.netbox_tls) == 0
    error_message = "no TLS secret without TLS material"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.netbox.metadata[0].namespace == "test-ns"
    error_message = "deployment must land in var.namespace"
  }

  assert {
    condition     = contains(kubernetes_stateful_set_v1.netbox.spec[0].template[0].spec[0].container[0].security_context[0].capabilities[0].drop, "ALL")
    error_message = "server container must drop all capabilities"
  }
}

run "netbox_with_ingress" {
  command = plan

  module {
    source = "./modules/netbox"
  }

  variables {
    tls_cert = "dummy-cert"
    tls_key  = "dummy-key"
  }

  assert {
    condition     = length(kubernetes_ingress_v1.netbox) == 1
    error_message = "ingress must be created when TLS material is supplied"
  }

  assert {
    condition     = length(kubernetes_secret_v1.netbox_tls) == 1
    error_message = "TLS secret must be created when TLS material is supplied"
  }

  assert {
    condition     = kubernetes_ingress_v1.netbox[0].spec[0].rule[0].host == "netbox.example.local"
    error_message = "ingress host must be var.fqdn"
  }

  assert {
    condition     = kubernetes_ingress_v1.netbox[0].spec[0].ingress_class_name == "nginx"
    error_message = "ingress class must be nginx"
  }
}

run "netbox_rejects_short_secret_key" {
  command = plan

  module {
    source = "./modules/netbox"
  }

  variables {
    secret_key = "too-short"
  }

  expect_failures = [var.secret_key]
}
