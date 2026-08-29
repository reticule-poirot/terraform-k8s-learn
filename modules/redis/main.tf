locals {
  labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/version"    = var.redis_version
    "app.kubernetes.io/component"  = "kvstorage"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

resource "kubernetes_secret_v1" "redis_secret" {
  metadata {
    name      = "${var.name}-secret"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    redis_password : var.redis_password
  }
}

resource "kubernetes_service_v1" "redis_service" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = var.name
    }
    port {
      port = var.redis_port
    }
  }
}

resource "kubernetes_stateful_set_v1" "redis" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    service_name = kubernetes_service_v1.redis_service.metadata[0].name
    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.name
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
          image             = "redis:${var.redis_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          command           = var.command
          port {
            container_port = var.redis_port
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }
          readiness_probe {
            exec {
              command = ["/bin/sh", "-c", "redis-cli -a $(cat /run/secrets/redis_password) ping"]
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
          volume_mount {
            mount_path = "/data"
            name       = "redis-data"
          }
          volume_mount {
            mount_path = "/var/run/secrets/redis_password"
            name       = "redis-password"
            sub_path   = "redis_password"
          }
        }
        volume {
          name = "redis-password"
          secret {
            secret_name = kubernetes_secret_v1.redis_secret.metadata[0].name
            items {
              key  = "redis_password"
              path = "redis_password"
            }
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name      = "redis-data"
        namespace = var.namespace
        labels    = local.labels
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.redis_data_size
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_secret_v1.redis_secret,
    kubernetes_service_v1.redis_service,
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}
