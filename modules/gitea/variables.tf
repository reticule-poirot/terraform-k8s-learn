variable "name" {
  type        = string
  description = "Gitea pod name"
  default     = "gitea"
}

variable "gitea_version" {
  type        = string
  description = "Gitea version"
  default     = "latest-rootless"
}

variable "gitea_data_size" {
  type        = string
  description = "Gitea dats volume size"
  default     = "1Gi"
}

variable "gitea_db_user" {
  type        = string
  description = "Gitea db user"
  default     = "gitea"
}

variable "gitea_db" {
  type        = string
  description = "Gitea db"
  default     = "gitea"
}

variable "gitea_db_password" {
  type        = string
  description = "Netbox db password"
  sensitive   = true
}

variable "gitea_db_type" {
  type        = string
  description = "Gitea db type"
  default     = "postgres"
}

variable "gitea_db_service" {
  type        = string
  description = "Gitea database service"
}

variable "gitea_db_port" {
  type        = number
  description = "Gitea db port"
  default     = 5432
}