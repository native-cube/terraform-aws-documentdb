output "endpoint" {
  description = "Elastic cluster endpoint."
  value       = module.documentdb.elastic_cluster_endpoint
}
output "arn" {
  description = "Elastic cluster ARN."
  value       = module.documentdb.elastic_cluster_arn
}
