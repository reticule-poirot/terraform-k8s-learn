variable "host" {
  type        = string
  description = "Kubernetes cluster"
}

variable "client_certificate" {
  type        = string
  description = "Client certificate"
}

variable "client_key" {
  type        = string
  description = "Client key"
}

variable "cluster_ca_certificate" {
  type        = string
  description = "Cluster certificate"
}

variable "netbox_password" {
  type        = string
  description = "Netbox database password"
}

variable "gitea_db_password" {
  type        = string
  description = "Gitea database password"
}

variable "redis_password" {
  type        = string
  description = "Redis db password"
  sensitive   = true
}

variable "redis_cache_password" {
  type        = string
  description = "Redis db password"
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "Netbox secret key"
  sensitive   = true
}