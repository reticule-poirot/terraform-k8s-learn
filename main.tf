locals {
  redis_command = [
    "/bin/sh", "-c", "redis-server --appendonly yes --requirepass $(cat /run/secrets/redis_password)"
  ]
  redis_cache_command = ["/bin/sh", "-c", "redis-server --requirepass $(cat /run/secrets/redis_password)"]
}

module "netbox_postgresql" {
  source        = "./modules/postgresql"
  name          = "postgresql-netbox"
  psql_version  = "15-alpine"
  psql_user     = module.netbox_netbox.netbox_db_user
  psql_password = var.netbox_password
  psql_db       = module.netbox_netbox.netbox_db
}

module "gitea_postgresql" {
  source        = "./modules/postgresql"
  count         = var.enable_gitea ? 1 : 0
  name          = "postgresql-gitea"
  psql_version  = "15-alpine"
  psql_user     = var.enable_gitea ? module.netbox_gitea.gitea_db_user : ""
  psql_password = var.gitea_db_password
  psql_db       = var.enable_gitea ? module.netbox_gitea.gitea_db : ""
}

module "netbox_redis" {
  source         = "./modules/redis"
  for_each       = toset(["redis", "redis-cache"])
  name           = each.value
  redis_version  = "7-alpine"
  command        = each.value == "redis" ? local.redis_command : local.redis_cache_command
  redis_password = each.value == "redis" ? var.redis_password : var.redis_cache_password
}

module "netbox_netbox" {
  source               = "./modules/netbox"
  netbox_version       = "v3.6.2"
  fqdn                 = "netbox.example.local"
  netbox_db_password   = var.netbox_password
  netbox_db_service    = module.netbox_postgresql.service
  redis_password       = var.redis_password
  redis_cache_password = var.redis_cache_password
  redis_service        = module.netbox_redis["redis"].service
  redis_cache_service  = module.netbox_redis["redis-cache"].service
  secret_key           = var.secret_key
  tls_cert             = base64decode(var.netbox_tls_cert)
  tls_key              = base64decode(var.netbox_tls_key)
}

module "netbox_gitea" {
  source            = "./modules/gitea"
  count             = var.enable_gitea ? 1 : 0
  gitea_version     = "1.20.4"
  gitea_db_password = var.gitea_db_password
  gitea_db_service  = var.enable_gitea ? module.gitea_postgresql.service : ""
}