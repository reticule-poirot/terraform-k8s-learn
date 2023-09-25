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

variable "fqdn" {
  type        = string
  description = "Prometheus fqdn"
  default     = "prometheus.example.local"
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