locals {
  labels = {
    name       = var.name
    version    = var.prometheus_version
    managed-by = "terraform"
  }
}

resource "kubernetes_config_map_v1" "prometheus_config" {
  metadata {
    name      = "${var.name}-config"
    namespace = var.namespace
  }
  data = {
    "prometheus.yml" : var.prometheus_config
  }
}

resource "kubernetes_persistent_volume_claim_v1" "prometheus_pvc" {
  metadata {
    name      = "${var.name}-pvc"
    namespace = var.namespace
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

resource "kubernetes_service_v1" "prometheus_service" {
  metadata {
    name      = var.name
    namespace = var.namespace
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

resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name      = "${var.name}-ingress"
    namespace = var.namespace
    labels    = local.labels
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
              name = kubernetes_service_v1.prometheus_service.metadata[0].name
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
    kubernetes_service_v1.prometheus_service
  ]
}

resource "kubernetes_deployment_v1" "prometheus" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
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
        security_context {
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }
        container {
          image             = "prom/prometheus:${var.prometheus_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              memory = "512Mi"
            }
          }
          port {
            container_port = 9090
          }
          volume_mount {
            mount_path = "/etc/prometheus/"
            name       = "${var.name}-config"
          }
          volume_mount {
            mount_path = "/prometheus"
            name       = "${var.name}-data"
          }
        }
        volume {
          name = "${var.name}-config"
          config_map {
            name = kubernetes_config_map_v1.prometheus_config.metadata[0].name
          }
        }
        volume {
          name = "${var.name}-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.prometheus_pvc.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_service_v1.prometheus_service,
    kubernetes_config_map_v1.prometheus_config,
    kubernetes_persistent_volume_claim_v1.prometheus_pvc,
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}
