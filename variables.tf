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