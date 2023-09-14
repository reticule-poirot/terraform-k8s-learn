output "service" {
  description = "Postgresql service name"
  value       = kubernetes_service.postgresql_service.metadata[0].name
}