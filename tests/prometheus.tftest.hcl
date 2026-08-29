# Plan-level checks for the prometheus module. No cluster required.

provider "kubernetes" {}

run "prometheus_wiring" {
  command = plan

  module {
    source = "./modules/prometheus"
  }

  variables {
    prometheus_version = "v3.1.0"
    prometheus_config  = "global:\n  scrape_interval: 15s\n"
  }

  assert {
    condition     = kubernetes_deployment_v1.prometheus.spec[0].template[0].spec[0].container[0].image == "prom/prometheus:v3.1.0"
    error_message = "image must be prom/prometheus:<prometheus_version>"
  }

  assert {
    condition     = kubernetes_service_v1.prometheus_service.spec[0].port[0].port == 9090
    error_message = "service must expose port 9090"
  }

  assert {
    condition     = kubernetes_config_map_v1.prometheus_config.data["prometheus.yml"] == "global:\n  scrape_interval: 15s\n"
    error_message = "config map must carry var.prometheus_config verbatim"
  }

  assert {
    condition     = kubernetes_persistent_volume_claim_v1.prometheus_pvc.spec[0].resources[0].requests.storage == "0.5Gi"
    error_message = "pvc must request the default 0.5Gi"
  }
}
