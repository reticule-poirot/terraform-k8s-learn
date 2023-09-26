variable "redis_version" {
  type        = string
  description = "Redis version"
}

variable "redis_port" {
  type        = number
  description = "Redis port"
  default     = 6379
}

variable "name" {
  type        = string
  description = "Redis pod name"
}

variable "redis_password" {
  type        = string
  description = "Redis db password"
  sensitive   = true
}

variable "redis_data_size" {
  type        = string
  description = "Redis data volume size"
  default     = "1Gi"
}

variable "command" {
  type        = list(string)
  description = "Redis container entry point"
}