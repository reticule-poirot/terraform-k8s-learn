# Plan-level checks for the postgresql module. No cluster required.

provider "kubernetes" {}

variables {
  namespace = "test-ns"
}

run "postgresql_wiring" {
  command = plan

  module {
    source = "./modules/postgresql"
  }

  variables {
    name          = "postgresql-netbox"
    psql_version  = "18-alpine"
    psql_user     = "netbox"
    psql_password = "test-password"
    psql_db       = "netbox"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.postgresql.spec[0].template[0].spec[0].container[0].image == "postgres:18-alpine"
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
    condition     = kubernetes_stateful_set_v1.postgresql.metadata[0].namespace == "test-ns"
    error_message = "StatefulSet must land in var.namespace"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.postgresql.spec[0].volume_claim_template[0].metadata[0].name == "postgresql-data"
    error_message = "storage must come from a volume_claim_template named postgresql-data"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.postgresql.spec[0].volume_claim_template[0].spec[0].resources[0].requests.storage == "1Gi"
    error_message = "volume_claim_template must request the default 1Gi"
  }

  assert {
    condition     = kubernetes_config_map_v1.postgresql_env.data["POSTGRES_PASSWORD_FILE"] == "/run/secrets/postgres_password"
    error_message = "env config map must point POSTGRES_PASSWORD_FILE at the mounted secret"
  }

  assert {
    condition     = startswith(kubernetes_config_map_v1.postgresql_env.data["PGDATA"], "/var/lib/postgresql/data/")
    error_message = "PGDATA must be pinned under the mounted volume (postgres >= 18 relocates it otherwise)"
  }
}

run "postgresql_custom_size" {
  command = plan

  module {
    source = "./modules/postgresql"
  }

  variables {
    name           = "postgresql-gitea"
    psql_version   = "18-alpine"
    psql_user      = "gitea"
    psql_password  = "test-password"
    psql_db        = "gitea"
    psql_port      = 5433
    psql_data_size = "5Gi"
  }

  assert {
    condition     = kubernetes_service_v1.postgresql_service.spec[0].port[0].port == 5433
    error_message = "service port must follow psql_port"
  }

  assert {
    condition     = kubernetes_stateful_set_v1.postgresql.spec[0].volume_claim_template[0].spec[0].resources[0].requests.storage == "5Gi"
    error_message = "volume_claim_template request must follow psql_data_size"
  }
}
