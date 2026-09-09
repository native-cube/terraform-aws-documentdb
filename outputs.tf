output "cluster_identifier" {
  description = "Cluster identifier."
  value       = try(aws_docdb_cluster.main[0].cluster_identifier, null)
}

output "cluster_arn" {
  description = "Cluster ARN."
  value       = try(aws_docdb_cluster.main[0].arn, null)
}

output "cluster_resource_id" {
  description = "Immutable regional cluster resource ID."
  value       = try(aws_docdb_cluster.main[0].cluster_resource_id, null)
}

output "cluster_endpoint" {
  description = "Writer DNS endpoint, available to dependent resources after module-managed instances and security group rules complete."
  value       = try(aws_docdb_cluster.main[0].endpoint, null)

  depends_on = [
    aws_docdb_cluster_instance.main,
    aws_vpc_security_group_ingress_rule.main,
    aws_vpc_security_group_egress_rule.main
  ]
}

output "cluster_reader_endpoint" {
  description = "Reader DNS endpoint, available to dependent resources after module-managed instances and security group rules complete."
  value       = try(aws_docdb_cluster.main[0].reader_endpoint, null)

  depends_on = [
    aws_docdb_cluster_instance.main,
    aws_vpc_security_group_ingress_rule.main,
    aws_vpc_security_group_egress_rule.main
  ]
}

output "cluster_port" {
  description = "Database port."
  value       = try(aws_docdb_cluster.main[0].port, null)
}

output "cluster_hosted_zone_id" {
  description = "Endpoint Route 53 hosted zone ID."
  value       = try(aws_docdb_cluster.main[0].hosted_zone_id, null)
}

output "cluster_engine_version" {
  description = "Actual engine version."
  value       = try(aws_docdb_cluster.main[0].engine_version, null)
}

output "cluster_members" {
  description = "Cluster instance identifiers."
  value       = try(aws_docdb_cluster.main[0].cluster_members, null)
}

output "master_user_secret" {
  description = "Managed secret metadata only: ARN, KMS key, and status. No password is returned."
  value       = try(aws_docdb_cluster.main[0].master_user_secret, null)
}

output "master_user_secret_arn" {
  description = "ARN of the DocumentDB-managed password secret, when available."
  value       = try(aws_docdb_cluster.main[0].master_user_secret[0].secret_arn, null)
}

output "instances" {
  description = "Instance metadata keyed by the caller-provided instance keys, available after module-managed instances and security group rules complete."
  value = { for key, instance in aws_docdb_cluster_instance.main : key => {
    identifier         = instance.identifier
    arn                = instance.arn
    endpoint           = instance.endpoint
    port               = instance.port
    availability_zone  = instance.availability_zone
    engine_version     = instance.engine_version
    dbi_resource_id    = instance.dbi_resource_id
    writer             = instance.writer
    instance_class     = instance.instance_class
    ca_cert_identifier = instance.ca_cert_identifier
    storage_encrypted  = instance.storage_encrypted
  } }

  depends_on = [
    aws_vpc_security_group_ingress_rule.main,
    aws_vpc_security_group_egress_rule.main
  ]
}

output "global_cluster_arn" {
  description = "DocumentDB global container arn."
  value       = try(aws_docdb_global_cluster.main[0].arn, null)
}

output "global_cluster_id" {
  description = "DocumentDB global container global cluster identifier."
  value       = try(aws_docdb_global_cluster.main[0].global_cluster_identifier, null)
}

output "global_cluster_resource_id" {
  description = "DocumentDB global container global cluster resource id."
  value       = try(aws_docdb_global_cluster.main[0].global_cluster_resource_id, null)
}

output "global_cluster_members" {
  description = "DocumentDB global container global cluster members."
  value       = try(aws_docdb_global_cluster.main[0].global_cluster_members, null)
}

output "global_cluster_status" {
  description = "DocumentDB global container status."
  value       = try(aws_docdb_global_cluster.main[0].status, null)
}

output "elastic_cluster_arn" {
  description = "Elastic cluster arn."
  value       = try(aws_docdbelastic_cluster.main[0].arn, null)
}

output "elastic_cluster_endpoint" {
  description = "Elastic cluster endpoint, available to dependent resources after the cluster and module-managed security group rules complete."
  value       = try(aws_docdbelastic_cluster.main[0].endpoint, null)

  depends_on = [
    aws_vpc_security_group_ingress_rule.main,
    aws_vpc_security_group_egress_rule.main
  ]
}

output "elastic_cluster_id" {
  description = "Elastic cluster id."
  value       = try(aws_docdbelastic_cluster.main[0].id, null)
}

output "security_group_id" {
  description = "Module-created security group ID."
  value       = try(aws_security_group.main[0].id, null)
}

output "security_group_ids" {
  description = "Security group IDs attached to the cluster."
  value       = local.create_cluster ? local.security_group_ids : []
}

output "db_subnet_group_name" {
  description = "Managed or supplied subnet group name."
  value       = local.create_docdb ? local.db_subnet_group_name : null
}

output "db_subnet_group_arn" {
  description = "Module-created subnet group ARN."
  value       = try(aws_docdb_subnet_group.main[0].arn, null)
}

output "cluster_parameter_group_name" {
  description = "Managed or supplied cluster parameter group name."
  value       = local.create_docdb ? local.parameter_group_name : null
}

output "cluster_parameter_group_arn" {
  description = "Module-created parameter group ARN."
  value       = try(aws_docdb_cluster_parameter_group.main[0].arn, null)
}

output "cloudwatch_log_group_arns" {
  description = "Log group ARNs keyed by export type."
  value       = { for key, group in aws_cloudwatch_log_group.main : key => group.arn }
}

output "event_subscription_arns" {
  description = "Event subscription ARNs keyed by caller names."
  value       = { for key, subscription in aws_docdb_event_subscription.main : key => subscription.arn }
}

output "snapshot_arns" {
  description = "Snapshot ARNs keyed by caller names."
  value       = { for key, snapshot in aws_docdb_cluster_snapshot.main : key => snapshot.db_cluster_snapshot_arn }
}
