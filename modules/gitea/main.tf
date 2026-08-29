locals {
  gitea_volumes = ["data", "config"]
}

resource "kubernetes_config_map_v1" "gitea_env" {
  metadata {
    name      = "${var.name}-env"
    namespace = var.namespace
  }
  data = {
    GITEA__database__DB_TYPE = var.gitea_db_type
    GITEA__database__HOST    = "${var.gitea_db_service}:${var.gitea_db_port}"
    GITEA__database__NAME    = var.gitea_db
    GITEA__database__USER    = var.gitea_db_user
  }
}

resource "kubernetes_secret_v1" "gitea_secret" {
  metadata {
    name      = "${var.name}-secret"
    namespace = var.namespace
  }
  data = {
    GITEA__database__PASSWD = var.gitea_db_password
  }
}

resource "kubernetes_persistent_volume_claim_v1" "gitea_pvc" {
  for_each = toset(local.gitea_volumes)
  # Default StorageClass is WaitForFirstConsumer — bind happens when the pod
  # schedules, so don't block apply on Bound.
  wait_until_bound = false
  metadata {
    name      = "${var.name}-${each.value}-pvc"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.gitea_data_size
      }
    }
  }
}

resource "kubernetes_service_v1" "gitea_service" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }
  spec {
    selector = {
      name = var.name
    }
    port {
      port        = 8080
      name        = "http"
      target_port = 3000
    }
    port {
      port = 2222
      name = "ssh"
    }
  }
}

resource "kubernetes_deployment_v1" "gitea" {
  metadata {
    name      = var.name
    namespace = var.namespace
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
        security_context {
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }
        container {
          image             = "gitea/gitea:${var.gitea_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          # The rootful gitea image starts as root and drops to the git user
          # itself, so no run_as_non_root / capability drop here — harden with
          # the rootless image if you need that.
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
            container_port = 3000
            name           = "gitea-web-http"
          }
          port {
            container_port = 2222
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.gitea_env.metadata[0].name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret_v1.gitea_secret.metadata[0].name
            }
          }
          volume_mount {
            mount_path = "/data"
            name       = "data"
          }
          volume_mount {
            mount_path = "/etc/gitea"
            name       = "config"
          }
        }
        dynamic "volume" {
          for_each = toset(local.gitea_volumes)
          content {
            name = volume.value
            persistent_volume_claim {
              claim_name = "${var.name}-${volume.value}-pvc"
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_config_map_v1.gitea_env,
    kubernetes_secret_v1.gitea_secret,
    kubernetes_persistent_volume_claim_v1.gitea_pvc,
    kubernetes_service_v1.gitea_service,
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}
