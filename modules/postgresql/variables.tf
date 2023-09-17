variable "name" {
  type        = string
  description = "Postgresql pod name"
}

variable "psql_version" {
  type        = string
  description = "Postgresql version"
}

variable "psql_user" {
  type        = string
  description = "Postgresql database user"
}

variable "psql_password" {
  type        = string
  description = "Postgresql user password"
  sensitive   = true
}

variable "psql_db" {
  type        = string
  description = "Postgresql database name"
}

variable "psql_data_size" {
  type        = string
  description = "Postgresql data volume size"
  default     = "1Gi"
}