locals {
  psql_secrets = ["postgres-password", "postgres-user", "postgres-db"]
  labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/version"    = var.psql_version
    "app.kubernetes.io/component"  = "database"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

resource "kubernetes_config_map_v1" "postgresql_env" {
  metadata {
    name      = "${var.name}-env"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    POSTGRES_PASSWORD_FILE = "/run/secrets/postgres_password"
    POSTGRES_USER_FILE     = "/run/secrets/postgres_user"
    POSTGRES_DB_FILE       = "/run/secrets/postgres_db"
    # Pin PGDATA to a subdirectory of the mounted volume. postgres >= 18 images
    # otherwise default PGDATA to a version-specific path (/var/lib/postgresql/18/docker)
    # outside the mount, and move VOLUME up to /var/lib/postgresql.
    PGDATA = "/var/lib/postgresql/data/pgdata"
  }
}

resource "kubernetes_secret_v1" "postgresql_secret" {
  metadata {
    name      = "${var.name}-secret"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    postgres_user : var.psql_user
    postgres_password : var.psql_password
    postgres_db : var.psql_db
  }
}

resource "kubernetes_service_v1" "postgresql_service" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
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

resource "kubernetes_stateful_set_v1" "postgresql" {
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
    service_name = kubernetes_service_v1.postgresql_service.metadata[0].name
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
          image             = "postgres:${var.psql_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          port {
            container_port = var.psql_port
          }
          security_context {
            allow_privilege_escalation = false
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
          startup_probe {
            exec {
              command = ["/bin/sh", "-c", "pg_isready"]
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.postgresql_env.metadata[0].name
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
              secret_name = kubernetes_secret_v1.postgresql_secret.metadata[0].name
              items {
                key  = replace(volume.value, "-", "_")
                path = replace(volume.value, "-", "_")
              }
            }
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name      = "postgresql-data"
        namespace = var.namespace
        labels    = local.labels
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
  }
  depends_on = [
    kubernetes_config_map_v1.postgresql_env,
    kubernetes_secret_v1.postgresql_secret,
    kubernetes_service_v1.postgresql_service,
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}
