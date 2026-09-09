locals {
  create_cluster        = var.create && var.create_cluster
  create_docdb          = local.create_cluster && var.cluster_type == "instance"
  create_elastic        = local.create_cluster && var.cluster_type == "elastic"
  create_global         = var.create && var.create_global_cluster
  create_subnet_group   = local.create_docdb && var.create_db_subnet_group
  create_security_group = local.create_cluster && var.create_security_group
  is_restore            = var.snapshot_identifier != null || var.restore_to_point_in_time != null
  use_master_username   = local.create_docdb && var.is_primary_cluster && !local.is_restore
  use_credentials       = local.create_docdb && var.is_primary_cluster && (!local.is_restore || var.manage_credentials_after_restore)
  is_global             = var.create_global_cluster || var.global_cluster_identifier != null
  validate_network      = local.create_cluster && var.validate_network_configuration
  validate_engine       = local.create_docdb && var.validate_engine_capabilities

  common_tags = merge(var.tags, {
    "terraform-module" = "documentdb"
    "documentdb"       = var.name
  })

  instances = local.create_docdb ? var.instances : {}
  instance_classes = {
    for key, instance in local.instances : key => coalesce(instance.instance_class, var.instance_class)
  }
  instance_performance_insights_enabled = {
    for key, instance in local.instances : key => coalesce(instance.enable_performance_insights, var.enable_performance_insights)
  }
  db_subnet_group_name = local.create_subnet_group ? aws_docdb_subnet_group.main[0].name : (
    local.validate_network && local.create_docdb ? data.aws_db_subnet_group.existing[0].name : var.db_subnet_group_name
  )
  parameter_group_name = local.create_docdb && var.cluster_parameter_group != null ? (
    aws_docdb_cluster_parameter_group.main[0].name
  ) : var.db_cluster_parameter_group_name
  external_security_group_ids = local.validate_network ? [
    for index, id in var.security_group_ids : data.aws_security_group.selected[tostring(index)].id
  ] : var.security_group_ids
  security_group_ids        = concat(local.external_security_group_ids, local.create_security_group ? [aws_security_group.main[0].id] : [])
  global_cluster_identifier = local.create_global ? aws_docdb_global_cluster.main[0].global_cluster_identifier : var.global_cluster_identifier
  subnet_vpc_ids            = toset([for subnet in data.aws_subnet.selected : subnet.vpc_id])
  subnet_azs                = toset([for subnet in data.aws_subnet.selected : subnet.availability_zone])
}
