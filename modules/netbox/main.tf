locals {
  netbox_volumes = ["media", "reports", "scripts"]
  netbox_secrets = ["db-password", "redis-password", "redis-cache-password", "secret-key"]
}

resource "kubernetes_config_map" "netbox_env" {
  metadata {
    name = "${var.name}-env"
  }
  data = {
    ALLOWED_HOSTS    = var.fqdn
    DB_NAME          = var.netbox_db
    DB_PORT          = var.netbox_db_port
    DB_USER          = var.netbox_db_user
    DB_HOST          = var.netbox_db_service
    REDIS_HOST       = var.redis_service
    REDIS_PORT       = var.redis_port
    REDIS_CACHE_HOST = var.redis_cache_service
    REDIS_CACHE_PORT = var.redis_port
    DB_WAIT_DEBUG    = 1
  }
}

resource "kubernetes_secret" "netbox_secret" {
  metadata {
    name = "${var.name}-secret"
  }
  data = {
    db_password : var.netbox_db_password
    redis_password : var.redis_password
    redis_cache_password : var.redis_cache_password
    secret_key : var.secret_key
  }
}

resource "kubernetes_persistent_volume_claim" "netbox_pvc" {
  for_each = toset(local.netbox_volumes)
  metadata {
    name = "${var.name}-${each.value}-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.netbox_data_size
      }
    }
  }
}

resource "kubernetes_service" "netbox_service" {
  metadata {
    name = var.name
  }
  spec {
    selector = {
      name = var.name
    }
    port {
      port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "netbox" {
  metadata {
    name = "netbox-ingres"
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
              name = kubernetes_service.netbox_service.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "netbox" {
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
          image             = "netboxcommunity/netbox:${var.netbox_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          port {
            container_port = 8080
          }
          liveness_probe {
            http_get {
              port = "8080"
              path = "/api/"
            }
            initial_delay_seconds = 240
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.netbox_env.metadata[0].name
            }
          }
          dynamic "volume_mount" {
            for_each = toset(local.netbox_volumes)
            content {
              mount_path = "/opt/netbox/netbox/${volume_mount.value}"
              name       = volume_mount.value
              read_only  = true
            }
          }
          dynamic "volume_mount" {
            for_each = toset(local.netbox_secrets)
            content {
              mount_path = "/var/run/secrets/${replace(volume_mount.value, "-", "_")}"
              name       = "${volume_mount.value}-secret"
              sub_path   = replace(volume_mount.value, "-", "_")
            }
          }
        }
        container {
          image             = "netboxcommunity/netbox:${var.netbox_version}"
          image_pull_policy = "IfNotPresent"
          name              = "${var.name}-worker"
          command           = ["/bin/sh", "-c", "/opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py rqworker"]
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "ps -aux | grep -v grep | grep -q rqworker || exit 1"]
            }
            initial_delay_seconds = 10
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.netbox_env.metadata[0].name
            }
          }
          dynamic "volume_mount" {
            for_each = toset(local.netbox_volumes)
            content {
              mount_path = "/opt/netbox/netbox/${volume_mount.value}"
              name       = volume_mount.value
              read_only  = true
            }
          }
          dynamic "volume_mount" {
            for_each = toset(local.netbox_secrets)
            content {
              mount_path = "/var/run/secrets/${replace(volume_mount.value, "-", "_")}"
              name       = "${volume_mount.value}-secret"
              sub_path   = replace(volume_mount.value, "-", "_")
            }
          }
        }
        dynamic "volume" {
          for_each = toset(local.netbox_volumes)
          content {
            name = volume.value
            persistent_volume_claim {
              claim_name = "${var.name}-${volume.value}-pvc"
            }
          }
        }
        dynamic "volume" {
          for_each = toset(local.netbox_secrets)
          content {
            name = "${volume.value}-secret"
            secret {
              secret_name = kubernetes_secret.netbox_secret.metadata[0].name
              items {
                key  = replace(volume.value, "-", "_")
                path = replace(volume.value, "-", "_")
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_config_map.netbox_env,
    kubernetes_secret.netbox_secret,
    kubernetes_persistent_volume_claim.netbox_pvc,
    kubernetes_service.netbox_service
  ]
  timeouts {
    create = "2m"
    update = "2m"
  }
}

resource "kubernetes_cron_job_v1" "netbox_cron" {
  metadata {
    name = "${var.name}-housekeeper"
  }
  spec {
    schedule = "0 1 * * *"
    job_template {
      metadata {
        name = "${var.name}-housekeeper"
      }
      spec {
        template {
          metadata {
            name = "${var.name}-housekeeper"
          }
          spec {
            container {
              image             = "netboxcommunity/netbox:${var.netbox_version}"
              image_pull_policy = "IfNotPresent"
              name              = "${var.name}-housekeeper"
              command           = ["/bin/sh", "-c", "/opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py housekeeping"]
              liveness_probe {
                exec {
                  command = ["/bin/sh", "-c", "ps -aux | grep -v grep | grep -q housekeeping || exit 1"]
                }
                initial_delay_seconds = 10
              }
              env_from {
                config_map_ref {
                  name = kubernetes_config_map.netbox_env.metadata[0].name
                }
              }
              dynamic "volume_mount" {
                for_each = toset(local.netbox_volumes)
                content {
                  mount_path = "/opt/netbox/netbox/${volume_mount.value}"
                  name       = volume_mount.value
                  read_only  = true
                }
              }
              dynamic "volume_mount" {
                for_each = toset(local.netbox_secrets)
                content {
                  mount_path = "/var/run/secrets/${replace(volume_mount.value, "-", "_")}"
                  name       = "${volume_mount.value}-secret"
                  sub_path   = replace(volume_mount.value, "-", "_")
                }
              }
            }
            dynamic "volume" {
              for_each = toset(local.netbox_volumes)
              content {
                name = volume.value
                persistent_volume_claim {
                  claim_name = "${var.name}-${volume.value}-pvc"
                }
              }
            }
            dynamic "volume" {
              for_each = toset(local.netbox_secrets)
              content {
                name = "${volume.value}-secret"
                secret {
                  secret_name = kubernetes_secret.netbox_secret.metadata[0].name
                  items {
                    key  = replace(volume.value, "-", "_")
                    path = replace(volume.value, "-", "_")
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}