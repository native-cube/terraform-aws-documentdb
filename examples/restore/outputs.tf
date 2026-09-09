output "endpoint" {
  description = "Cluster writer endpoint."
  value       = module.documentdb.cluster_endpoint
}
output "reader_endpoint" {
  description = "Cluster reader endpoint."
  value       = module.documentdb.cluster_reader_endpoint
}
output "master_user_secret_arn" {
  description = "Managed credential secret ARN."
  value       = module.documentdb.master_user_secret_arn
}
