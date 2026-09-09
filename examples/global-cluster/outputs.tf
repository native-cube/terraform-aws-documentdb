output "global_cluster_id" {
  description = "Global database identifier."
  value       = module.primary.global_cluster_id
}
output "primary_endpoint" {
  description = "Primary writer endpoint."
  value       = module.primary.cluster_endpoint
}
output "secondary_reader_endpoint" {
  description = "Secondary read-only endpoint."
  value       = module.secondary.cluster_reader_endpoint
}
