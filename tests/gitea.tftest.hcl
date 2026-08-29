# Plan-level checks for the gitea module. No cluster required.

provider "kubernetes" {}

run "gitea_wiring" {
  command = plan

  module {
    source = "./modules/gitea"
  }

  variables {
    gitea_version     = "1.22.3"
    gitea_db_password = "test-password"
    gitea_db_service  = "postgresql-gitea"
  }

  assert {
    condition     = kubernetes_deployment_v1.gitea.spec[0].template[0].spec[0].container[0].image == "gitea/gitea:1.22.3"
    error_message = "image must be gitea/gitea:<gitea_version>"
  }

  assert {
    condition     = kubernetes_config_map_v1.gitea_env.data["GITEA__database__HOST"] == "postgresql-gitea:5432"
    error_message = "DB host must combine gitea_db_service and gitea_db_port"
  }

  assert {
    condition     = kubernetes_config_map_v1.gitea_env.data["GITEA__database__DB_TYPE"] == "postgres"
    error_message = "DB type must default to postgres"
  }

  assert {
    condition     = kubernetes_config_map_v1.gitea_env.data["GITEA__database__NAME"] == "gitea"
    error_message = "DB name must default to gitea"
  }

  assert {
    condition     = length(kubernetes_service_v1.gitea_service.spec[0].port) == 2
    error_message = "service must expose http and ssh ports"
  }

  assert {
    condition     = length(kubernetes_persistent_volume_claim_v1.gitea_pvc) == 2
    error_message = "module must create data and config PVCs"
  }
}

run "gitea_custom_db" {
  command = plan

  module {
    source = "./modules/gitea"
  }

  variables {
    gitea_version     = "1.22.3"
    gitea_db_password = "test-password"
    gitea_db_service  = "db.example"
    gitea_db_port     = 6432
    gitea_db_user     = "forge"
    gitea_db          = "forge"
  }

  assert {
    condition     = kubernetes_config_map_v1.gitea_env.data["GITEA__database__HOST"] == "db.example:6432"
    error_message = "DB host must follow gitea_db_service and gitea_db_port"
  }

  assert {
    condition     = kubernetes_config_map_v1.gitea_env.data["GITEA__database__USER"] == "forge"
    error_message = "DB user must follow gitea_db_user"
  }
}
