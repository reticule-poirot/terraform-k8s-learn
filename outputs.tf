output "namespace" {
  description = "Namespace the stack is deployed into"
  value       = local.namespace
}

output "netbox_url" {
  description = "URL the NetBox ingress serves"
  value       = "https://${module.netbox_netbox.fqdn}"
}

output "netbox_service" {
  description = "In-cluster NetBox service name and port"
  value       = module.netbox_netbox.service
}

output "gitea_enabled" {
  description = "Whether the Gitea stack is deployed"
  value       = var.enable_gitea
}

output "prometheus_enabled" {
  description = "Whether the Prometheus stack is deployed"
  value       = var.enable_prometheus
}
