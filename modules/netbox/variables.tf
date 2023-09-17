variable "name" {
  type        = string
  description = "Netbox pod name"
  default     = "netbox"
}

variable "netbox_version" {
  type        = string
  description = "Netbox version"
  default     = "latest"
}

variable "netbox_db_user" {
  type        = string
  description = "Netbox db user"
  default     = "netbox"
}

variable "netbox_db_password" {
  type        = string
  description = "Netbox db password"
  sensitive   = true
}

variable "netbox_db" {
  type        = string
  description = "Netbox database name"
  default     = "netbox"
}

variable "netbox_data_size" {
  type        = string
  description = "Netbox data volume size"
  default     = "0.5Gi"
}

variable "netbox_db_service" {
  type        = string
  description = "Netbox database service"
}

variable "netbox_db_port" {
  type        = number
  description = "Netbox db port"
  default     = 5432
}

variable "redis_port" {
  type        = number
  description = "Redis db port"
  default     = 6379
}

variable "redis_service" {
  type        = string
  description = "Redis service"
}

variable "redis_password" {
  type        = string
  description = "Redis password"
  sensitive   = true
}

variable "redis_cache_service" {
  type        = string
  description = "Redis cache service"
}

variable "redis_cache_password" {
  type        = string
  description = "Redis cache password"
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "Netbox secret key"
  sensitive   = true
  validation {
    condition     = length(var.secret_key) >= 50
    error_message = "Length < 50"
  }
}