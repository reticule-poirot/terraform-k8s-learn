resource "kubernetes_secret" "redis_secret" {
  metadata {
    name = "${var.name}-secret"
  }
  data = {
    redis_password : var.redis_password
  }
}

resource "kubernetes_persistent_volume_claim" "redis_pvc" {
  metadata {
    name = "${var.name}-pvc"
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

resource "kubernetes_service" "redis_service" {
  metadata {
    name = var.name
  }
  spec {
    selector = {
      name = var.name
    }
    port {
      port = 6379
    }
  }
}

resource "kubernetes_deployment" "redis_deployment" {
  metadata {
    name = var.name
  }
  spec {
    selector {
      match_labels = {
        name = var.name
      }
    }
    template {
      metadata {
        labels = {
          name = var.name
        }
      }
      spec {
        container {
          image             = "redis:${var.redis_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          command           = var.command
          port {
            container_port = 6379
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
          name = "redis-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis_pvc.metadata[0].name
          }
        }
        volume {
          name = "redis-password"
          secret {
            secret_name = kubernetes_secret.redis_secret.metadata[0].name
            items {
              key  = "redis_password"
              path = "redis_password"
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_secret.redis_secret,
    kubernetes_persistent_volume_claim.redis_pvc,
    kubernetes_service.redis_service,
    kubernetes_service.redis_service
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}

