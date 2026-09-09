resource "aws_docdbelastic_cluster" "main" {
  count = local.create_elastic ? 1 : 0

  region                       = var.region
  name                         = var.name
  admin_user_name              = try(var.elastic_cluster.admin_user_name, null)
  admin_user_password          = var.elastic_admin_user_password
  auth_type                    = try(var.elastic_cluster.auth_type, null)
  shard_capacity               = try(var.elastic_cluster.shard_capacity, null)
  shard_count                  = try(var.elastic_cluster.shard_count, null)
  shard_instance_count         = try(var.elastic_cluster.shard_instance_count, null)
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  kms_key_id                   = var.kms_key_id
  subnet_ids                   = var.subnet_ids
  vpc_security_group_ids       = local.security_group_ids
  tags                         = local.common_tags

  dynamic "timeouts" {
    for_each = var.elastic_cluster_timeouts == null ? [] : [var.elastic_cluster_timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = !local.validate_network || (length(local.subnet_vpc_ids) == 1 && length(local.subnet_azs) >= 2)
      error_message = "Elastic subnets must share a VPC and span at least two Availability Zones."
    }
    precondition {
      condition     = var.elastic_cluster != null && var.elastic_admin_user_password != null
      error_message = "Elastic deployments require elastic_cluster settings and elastic_admin_user_password."
    }
    precondition {
      condition     = length(var.subnet_ids) >= 2 && (var.create_security_group || length(var.security_group_ids) > 0)
      error_message = "Elastic requires at least two subnet IDs and a managed or existing security group."
    }
    precondition {
      condition     = !local.is_global && !local.is_restore && var.serverless_v2_scaling_configuration == null && var.cluster_parameter_group == null && var.db_cluster_parameter_group_name == null && length(var.enabled_cloudwatch_logs_exports) == 0
      error_message = "Elastic cannot use global membership, instance-cluster restores, Serverless scaling, parameter groups, or log exports."
    }
    precondition {
      condition     = var.port == 27017 && var.network_type == "IPV4" && var.storage_encrypted && var.storage_type == "standard" && var.cluster_identifier_prefix == null
      error_message = "Elastic uses port 27017, IPv4, encrypted storage, and name; instance-cluster storage and identifier options are unsupported."
    }
  }
}
