variable "name" {
  type        = string
  description = "Prometheus pod name"
  default     = "prometheus"
}

variable "prometheus_version" {
  type        = string
  description = "Prometheus version"
  default     = "latest"
}

variable "prometheus_config" {
  type        = string
  description = "Prometheus config"
}

variable "prometheus_data_size" {
  type        = string
  description = "Postgresql data volume size"
  default     = "0.5Gi"
}