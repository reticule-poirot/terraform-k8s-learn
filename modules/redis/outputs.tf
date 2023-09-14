output "service" {
  description = "Redis service name"
  value       = kubernetes_service.redis_service.metadata[0].name
}