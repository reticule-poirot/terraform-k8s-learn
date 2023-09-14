output "service" {
  value = kubernetes_service.postgresql_service.metadata[0].name
}