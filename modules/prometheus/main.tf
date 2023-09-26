locals {
  labels = {
    name       = var.name
    version    = var.prometheus_version
    managed-by = "terraform"
  }
}

resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name = "${var.name}-config"
  }
  data = {
    "prometheus.yml" : var.prometheus_config
  }
}

resource "kubernetes_persistent_volume_claim" "prometheus_pvc" {
  metadata {
    name = "${var.name}-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.prometheus_data_size
      }
    }
  }
}

resource "kubernetes_service" "prometheus_service" {
  metadata {
    name = var.name
  }
  spec {
    selector = {
      name = var.name
    }
    port {
      port = 9090
    }
  }
}

resource "kubernetes_ingress_v1" "netbox" {
  metadata {
    name   = "${var.name}-ingres"
    labels = local.labels
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.fqdn
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.prometheus_service.metadata[0].name
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_service.prometheus_service
  ]
}

resource "kubernetes_deployment" "prometheus" {
  metadata {
    name   = var.name
    labels = local.labels
  }
  spec {
    selector {
      match_labels = {
        name = var.name
      }
    }
    template {
      metadata {
        labels = local.labels
      }
      spec {
        container {
          image             = "prom/prometheus:${var.prometheus_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          port {
            container_port = 9090
          }
          volume_mount {
            mount_path = "/etc/prometheus/"
            name       = "${var.name}-config"
          }
        }
        volume {
          name = "${var.name}-config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_service.prometheus_service,
    kubernetes_config_map.prometheus_config,
    kubernetes_persistent_volume_claim.prometheus_pvc
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}