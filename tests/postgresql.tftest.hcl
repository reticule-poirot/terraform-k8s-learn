# Plan-level checks for the postgresql module. No cluster required.

provider "kubernetes" {}

run "postgresql_wiring" {
  command = plan

  module {
    source = "./modules/postgresql"
  }

  variables {
    name          = "postgresql-netbox"
    psql_version  = "15-alpine"
    psql_user     = "netbox"
    psql_password = "test-password"
    psql_db       = "netbox"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.postgresql.spec[0].template[0].spec[0].container[0].image == "postgres:15-alpine"
    error_message = "image must be postgres:<psql_version>"
  }

  assert {
    condition     = kubernetes_service_v1.postgresql_service.spec[0].port[0].port == 5432
    error_message = "service must expose the default port 5432"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.postgresql.spec[0].service_name == "postgresql-netbox"
    error_message = "StatefulSet serviceName must match the Service name"
  }

  assert {
    condition     = kubernetes_persistent_volume_v1.postgresql_pv.spec[0].persistent_volume_source[0].host_path[0].path == "/mnt/postgresql-netbox_psql_data"
    error_message = "hostPath must be derived from var.name"
  }

  assert {
    condition     = kubernetes_persistent_volume_v1.postgresql_pv.spec[0].storage_class_name == "hostpath"
    error_message = "PV must use the hostpath storage class"
  }

  assert {
    condition     = kubernetes_config_map_v1.postgresql_env.data["POSTGRES_PASSWORD_FILE"] == "/run/secrets/postgres_password"
    error_message = "env config map must point POSTGRES_PASSWORD_FILE at the mounted secret"
  }
}

run "postgresql_custom_size" {
  command = plan

  module {
    source = "./modules/postgresql"
  }

  variables {
    name           = "postgresql-gitea"
    psql_version   = "16-alpine"
    psql_user      = "gitea"
    psql_password  = "test-password"
    psql_db        = "gitea"
    psql_port      = 5433
    psql_data_size = "5Gi"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.postgresql.spec[0].template[0].spec[0].container[0].image == "postgres:16-alpine"
    error_message = "image tag must follow psql_version"
  }

  assert {
    condition     = kubernetes_service_v1.postgresql_service.spec[0].port[0].port == 5433
    error_message = "service port must follow psql_port"
  }

  assert {
    condition     = kubernetes_persistent_volume_claim_v1.postgresql_pvc.spec[0].resources[0].requests.storage == "5Gi"
    error_message = "pvc request must follow psql_data_size"
  }
}
