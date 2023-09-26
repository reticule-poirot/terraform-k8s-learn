output "name" {
  value = var.name
}

output "service" {
  value = {
    service = kubernetes_service.netbox_service.metadata[0].name,
    port    = kubernetes_service.netbox_service.spec[0].port[0].port
  }
}

output "netbox_db_user" {
  value = var.netbox_db_user
}

output "netbox_db" {
  value = var.netbox_db
}