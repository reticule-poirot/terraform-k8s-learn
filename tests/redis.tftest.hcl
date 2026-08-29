# Plan-level checks for the redis module. No cluster required.

provider "kubernetes" {}

run "redis_defaults" {
  command = plan

  module {
    source = "./modules/redis"
  }

  variables {
    name           = "redis"
    redis_version  = "7-alpine"
    redis_password = "test-password"
    command        = ["/bin/sh", "-c", "redis-server"]
  }

  assert {
    condition     = kubernetes_deployment_v1.redis_deployment.spec[0].template[0].spec[0].container[0].image == "redis:7-alpine"
    error_message = "container image must be redis:<redis_version>"
  }

  assert {
    condition     = kubernetes_service_v1.redis_service.spec[0].port[0].port == 6379
    error_message = "service must expose the default redis port 6379"
  }

  assert {
    condition     = kubernetes_secret_v1.redis_secret.metadata[0].name == "redis-secret"
    error_message = "secret must be named <name>-secret"
  }

  assert {
    condition     = kubernetes_persistent_volume_claim_v1.redis_pvc.spec[0].resources[0].requests.storage == "1Gi"
    error_message = "pvc must request the default 1Gi"
  }
}

run "redis_cache_overrides" {
  command = plan

  module {
    source = "./modules/redis"
  }

  variables {
    name            = "redis-cache"
    redis_version   = "7.4-alpine"
    redis_port      = 6380
    redis_data_size = "2Gi"
    redis_password  = "test-password"
    command         = ["/bin/sh", "-c", "redis-server --save ''"]
  }

  assert {
    condition     = kubernetes_deployment_v1.redis_deployment.spec[0].template[0].spec[0].container[0].image == "redis:7.4-alpine"
    error_message = "image tag must follow redis_version"
  }

  assert {
    condition     = kubernetes_service_v1.redis_service.spec[0].port[0].port == 6380
    error_message = "service port must follow redis_port"
  }

  assert {
    condition     = kubernetes_deployment_v1.redis_deployment.spec[0].template[0].spec[0].container[0].command[2] == "redis-server --save ''"
    error_message = "container command must come from var.command"
  }
}
