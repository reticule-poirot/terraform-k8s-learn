output "service" {
  description = "Redis service name and port"
  value = {
    service = kubernetes_service.redis_service.metadata[0].name,
    port    = kubernetes_service.redis_service.spec[0].port[0].port
  }
}