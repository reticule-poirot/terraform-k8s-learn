output "service" {
  description = "Postgresql service name and port"
  value = {
    service = kubernetes_service.postgresql_service.metadata[0].name,
    port    = kubernetes_service.postgresql_service.spec[0].port[0].port
  }
}