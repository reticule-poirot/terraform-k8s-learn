variable "redis_version" {
  type        = string
  description = "Redis version"
}

variable "name" {
  type        = string
  description = "Redis pod name"
}

variable "redis_password" {
  type        = string
  description = "Redis db password"
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