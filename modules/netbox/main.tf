locals {
  netbox_volumes = ["media", "reports", "scripts"]
  netbox_secrets = ["db-password", "redis-password", "redis-cache-password", "secret-key"]
  labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/version"    = var.netbox_version
    "app.kubernetes.io/component"  = "server"
    "app.kubernetes.io/managed-by" = "terraform"
  }
  allowed_hosts = [var.fqdn, var.name]
}

resource "kubernetes_config_map" "netbox_env" {
  metadata {
    name   = "${var.name}-env"
    labels = local.labels
  }
  data = {
    ALLOWED_HOSTS    = join(" ", local.allowed_hosts)
    DB_NAME          = var.netbox_db
    DB_PORT          = var.netbox_db_port
    DB_USER          = var.netbox_db_user
    DB_HOST          = var.netbox_db_service
    REDIS_HOST       = var.redis_service
    REDIS_PORT       = var.redis_port
    REDIS_CACHE_HOST = var.redis_cache_service
    REDIS_CACHE_PORT = var.redis_port
    DB_WAIT_DEBUG    = 1
    METRICS_ENABLED  = var.metrics_enable
  }
}

resource "kubernetes_secret" "netbox_tls" {
  count = var.use_ingress && var.tls_cert != null && var.tls_key != null ? 1 : 0
  metadata {
    name   = "${var.name}-tls"
    labels = local.labels
  }
  type = "tls"
  data = {
    "tls.crt" : var.tls_cert
    "tls.key" : var.tls_key
  }
}

resource "kubernetes_secret" "netbox_secret" {
  metadata {
    name   = "${var.name}-secret"
    labels = local.labels
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
    name   = "${var.name}-${each.value}-pvc"
    labels = local.labels
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
    name   = var.name
    labels = local.labels
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = var.name
    }
    port {
      port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "netbox" {
  count = var.use_ingress && var.tls_cert != null && var.tls_key != null ? 1 : 0
  metadata {
    name   = "${var.name}-ingres"
    labels = local.labels
  }
  spec {
    tls {
      secret_name = kubernetes_secret.netbox_tls[count.index].metadata[0].name
    }
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
  depends_on = [
    kubernetes_secret.netbox_tls,
    kubernetes_service.netbox_service
  ]
}

resource "kubernetes_deployment" "netbox" {
  metadata {
    name   = var.name
    labels = local.labels
  }
  spec {
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
        init_container {
          name              = "${var.name}-init"
          image_pull_policy = "IfNotPresent"
          image             = "busybox:1.36.1"
          command           = ["/bin/sh", "-c", "sleep 10"]
        }
        container {
          image             = "netboxcommunity/netbox:${var.netbox_version}"
          image_pull_policy = "IfNotPresent"
          name              = var.name
          port {
            container_port = 8080
          }
          startup_probe {
            exec {
              command = ["/bin/sh", "-c", "ps aux | grep [u]nitd"]
            }
            period_seconds    = 10
            failure_threshold = 30
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
    create = "7m"
    update = "2m"
  }
}

resource "kubernetes_cron_job_v1" "netbox_cron" {
  metadata {
    name   = "${var.name}-housekeeper"
    labels = local.labels
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