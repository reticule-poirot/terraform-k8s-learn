locals {
  psql_secrets = ["postgres-password", "postgres-user", "postgres-db"]
  labels = {
    name       = var.name
    version    = var.psql_version
    managed-by = "terraform"
  }
}

resource "kubernetes_config_map" "postgresql_env" {
  metadata {
    name   = "${var.name}-env"
    labels = local.labels
  }
  data = {
    POSTGRES_PASSWORD_FILE = "/run/secrets/postgres_password"
    POSTGRES_USER_FILE     = "/run/secrets/postgres_user"
    POSTGRES_DB_FILE       = "/run/secrets/postgres_db"
  }
}

resource "kubernetes_secret" "postgresql_secret" {
  metadata {
    name   = "${var.name}-secret"
    labels = local.labels
  }
  data = {
    postgres_user : var.psql_user
    postgres_password : var.psql_password
    postgres_db : var.psql_db
  }
}

resource "kubernetes_persistent_volume_claim" "postgresql_pvc" {
  metadata {
    name   = "${var.name}-pvc"
    labels = local.labels
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.psql_data_size
      }
    }
  }
}

resource "kubernetes_service" "postgresql_service" {
  metadata {
    name = var.name
  }
  spec {
    selector = {
      name = var.name
    }
    port {
      port = var.psql_port
    }
  }
}


resource "kubernetes_deployment" "postgresql" {
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
          image             = "postgres:${var.psql_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          port {
            container_port = var.psql_port
          }
          readiness_probe {
            exec {
              command = ["/bin/sh", "-c", "pg_isready"]
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.postgresql_env.metadata[0].name
            }
          }
          dynamic "volume_mount" {
            for_each = toset(local.psql_secrets)
            content {
              mount_path = "/var/run/secrets/${replace(volume_mount.value, "-", "_")}"
              name       = volume_mount.value
              sub_path   = replace(volume_mount.value, "-", "_")
            }
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = "postgresql-data"
          }
        }
        dynamic "volume" {
          for_each = toset(local.psql_secrets)
          content {
            name = volume.value
            secret {
              secret_name = kubernetes_secret.postgresql_secret.metadata[0].name
              items {
                key  = replace(volume.value, "-", "_")
                path = replace(volume.value, "-", "_")
              }
            }
          }
        }
        volume {
          name = "postgresql-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgresql_pvc.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_config_map.postgresql_env,
    kubernetes_secret.postgresql_secret,
    kubernetes_persistent_volume_claim.postgresql_pvc,
    kubernetes_service.postgresql_service
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}