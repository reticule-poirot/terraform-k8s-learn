output "name" {
  description = "Netbox pod name"
  value       = var.name
}

output "service" {
  description = "Netbox service name and port"
  value = {
    service = kubernetes_service.netbox_service.metadata[0].name,
    port    = kubernetes_service.netbox_service.spec[0].port[0].port
  }
}

output "netbox_db_user" {
  description = "Netbox db user"
  value       = var.netbox_db_user
}

output "netbox_db" {
  description = "Netbox database name"
  value       = var.netbox_db
}