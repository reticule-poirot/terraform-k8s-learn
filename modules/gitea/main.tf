locals {
  gitea_volumes = ["data", "config"]
}

resource "kubernetes_config_map" "gitea_env" {
  metadata {
    name = "${var.name}-env"
  }
  data = {
    GITEA__database__DB_TYPE = var.gitea_db_type
    GITEA__database__HOST    = "${var.gitea_db_service}:${var.gitea_db_port}"
    GITEA__database__NAME    = var.gitea_db
    GITEA__database__USER    = var.gitea_db_user
  }
}

resource "kubernetes_secret" "gitea_secret" {
  metadata {
    name = "${var.name}-secret"
  }
  data = {
    GITEA__database__PASSWD = var.gitea_db_password
  }
}

resource "kubernetes_persistent_volume_claim" "gitea_pvc" {
  for_each = toset(local.gitea_volumes)
  metadata {
    name = "${var.name}-${each.value}-pvc"
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

resource "kubernetes_service" "gitea_service" {
  metadata {
    name = var.name
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

resource "kubernetes_deployment" "gitea" {
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
          image             = "gitea/gitea:${var.gitea_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          port {
            container_port = 3000
            name           = "gitea-web-http"
          }
          port {
            container_port = 2222
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.gitea_env.metadata[0].name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.gitea_secret.metadata[0].name
            }
          }
          dynamic "volume_mount" {
            for_each = toset(local.gitea_volumes)
            content {
              mount_path = volume_mount.value
              name       = volume_mount.value
            }
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
    kubernetes_config_map.gitea_env,
    kubernetes_secret.gitea_secret,
    kubernetes_persistent_volume_claim.gitea_pvc,
    kubernetes_service.gitea_service
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}