output "service" {
  value = kubernetes_service.redis_service.metadata[0].name
}