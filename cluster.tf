resource "aws_docdb_cluster" "main" {
  count = local.create_docdb ? 1 : 0

  region                          = var.region
  cluster_identifier              = var.cluster_identifier_prefix == null ? var.name : null
  cluster_identifier_prefix       = var.cluster_identifier_prefix
  cluster_members                 = var.cluster_members
  engine                          = var.engine
  engine_version                  = var.engine_version
  master_username                 = local.use_master_username ? var.master_username : null
  manage_master_user_password     = local.use_credentials && var.manage_master_user_password ? true : null
  master_password                 = local.use_credentials ? var.master_password : null
  master_password_wo              = local.use_credentials ? var.master_password_wo : null
  master_password_wo_version      = local.use_credentials ? var.master_password_wo_version : null
  global_cluster_identifier       = local.global_cluster_identifier
  availability_zones              = var.availability_zones
  db_subnet_group_name            = local.db_subnet_group_name
  db_cluster_parameter_group_name = local.parameter_group_name
  vpc_security_group_ids          = local.security_group_ids
  network_type                    = var.network_type
  port                            = var.port
  storage_encrypted               = var.storage_encrypted
  storage_type                    = var.storage_type
  kms_key_id                      = var.kms_key_id
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  snapshot_identifier             = var.snapshot_identifier
  apply_immediately               = var.apply_immediately
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  tags                            = local.common_tags

  dynamic "restore_to_point_in_time" {
    for_each = var.restore_to_point_in_time == null ? [] : [var.restore_to_point_in_time]
    content {
      source_cluster_identifier  = restore_to_point_in_time.value.source_cluster_identifier
      restore_type               = restore_to_point_in_time.value.restore_type
      restore_to_time            = restore_to_point_in_time.value.restore_to_time
      use_latest_restorable_time = restore_to_point_in_time.value.use_latest_restorable_time ? true : null
    }
  }

  dynamic "serverless_v2_scaling_configuration" {
    for_each = var.serverless_v2_scaling_configuration == null ? [] : [var.serverless_v2_scaling_configuration]
    content {
      min_capacity = serverless_v2_scaling_configuration.value.min_capacity
      max_capacity = serverless_v2_scaling_configuration.value.max_capacity
    }
  }

  dynamic "timeouts" {
    for_each = var.cluster_timeouts == null ? [] : [var.cluster_timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [aws_cloudwatch_log_group.main]

  lifecycle {
    precondition {
      condition     = var.skip_final_snapshot || try(length(trimspace(var.final_snapshot_identifier)) > 0, false)
      error_message = "Provide a unique final_snapshot_identifier or explicitly set skip_final_snapshot = true."
    }
    precondition {
      condition     = var.kms_key_id == null || var.storage_encrypted
      error_message = "kms_key_id requires storage_encrypted = true."
    }
    precondition {
      condition     = !(var.snapshot_identifier != null && var.restore_to_point_in_time != null)
      error_message = "snapshot_identifier and restore_to_point_in_time are mutually exclusive."
    }
    precondition {
      condition     = !local.is_restore || !local.is_global
      error_message = "Restore into a standalone cluster before adding it to a global database; the provider restore paths do not attach global membership."
    }
    precondition {
      condition     = var.is_primary_cluster || (local.is_global && !var.create_global_cluster)
      error_message = "A secondary requires an existing global_cluster_identifier and cannot create the global container."
    }
    precondition {
      condition     = !local.use_credentials || !local.is_global || !var.manage_master_user_password
      error_message = "DocumentDB global databases do not support managed master passwords. Set manage_master_user_password = false and provide caller-managed credentials on the primary."
    }
    precondition {
      condition     = !local.use_credentials || var.manage_master_user_password || var.master_password != null || var.master_password_wo_version != null
      error_message = "Managing primary credentials requires managed passwords, master_password, or master_password_wo with master_password_wo_version."
    }
    precondition {
      condition     = !local.use_master_username || try(length(var.master_username) > 0, false)
      error_message = "A new primary requires master_username."
    }
    precondition {
      condition     = var.create_db_subnet_group || var.db_subnet_group_name != null
      error_message = "Provide db_subnet_group_name when create_db_subnet_group is false."
    }
    precondition {
      condition     = var.create_security_group || length(var.security_group_ids) > 0
      error_message = "Provide security_group_ids when create_security_group is false."
    }
    precondition {
      condition     = var.cluster_parameter_group == null || var.db_cluster_parameter_group_name == null
      error_message = "Use either cluster_parameter_group or db_cluster_parameter_group_name."
    }
    precondition {
      condition = !local.validate_engine ? true : length(setsubtract(
        var.enabled_cloudwatch_logs_exports, data.aws_docdb_engine_version.selected[0].exportable_log_types
      )) == 0
      error_message = "The selected regional engine version does not support the requested log exports."
    }
    precondition {
      condition = !local.validate_engine || var.cluster_parameter_group == null ? true : (
        var.cluster_parameter_group.family == data.aws_docdb_engine_version.selected[0].parameter_group_family
      )
      error_message = "The parameter group family must match the selected engine version."
    }
  }
}

resource "aws_docdb_cluster_instance" "main" {
  for_each = local.instances

  region                       = var.region
  cluster_identifier           = aws_docdb_cluster.main[0].cluster_identifier
  identifier                   = each.value.identifier_prefix == null ? coalesce(each.value.identifier, "${var.name}-${each.key}") : null
  identifier_prefix            = each.value.identifier_prefix
  instance_class               = local.instance_classes[each.key]
  engine                       = var.engine
  availability_zone            = each.value.availability_zone
  apply_immediately            = coalesce(each.value.apply_immediately, var.apply_immediately)
  auto_minor_version_upgrade   = coalesce(each.value.auto_minor_version_upgrade, var.auto_minor_version_upgrade)
  ca_cert_identifier           = each.value.ca_cert_identifier != null ? each.value.ca_cert_identifier : var.ca_cert_identifier
  certificate_rotation_restart = each.value.certificate_rotation_restart != null ? each.value.certificate_rotation_restart : var.certificate_rotation_restart
  copy_tags_to_snapshot        = coalesce(each.value.copy_tags_to_snapshot, var.copy_tags_to_snapshot)
  enable_performance_insights  = local.instance_performance_insights_enabled[each.key]
  performance_insights_kms_key_id = local.instance_performance_insights_enabled[each.key] ? (
    each.value.performance_insights_kms_key_id != null ? each.value.performance_insights_kms_key_id : var.performance_insights_kms_key_id
  ) : null
  preferred_maintenance_window = each.value.preferred_maintenance_window != null ? each.value.preferred_maintenance_window : var.preferred_maintenance_window
  promotion_tier               = each.value.promotion_tier
  tags                         = merge(local.common_tags, each.value.tags)

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : (var.instance_timeouts == null ? [] : [var.instance_timeouts])
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = local.instance_classes[each.key] != "db.serverless" || var.serverless_v2_scaling_configuration != null
      error_message = "db.serverless instances require serverless_v2_scaling_configuration on the cluster."
    }
    precondition {
      condition     = each.value.performance_insights_kms_key_id == null || local.instance_performance_insights_enabled[each.key]
      error_message = "An explicitly configured instance Performance Insights KMS key requires enable_performance_insights on that instance."
    }
    precondition {
      condition = !local.validate_engine || each.value.availability_zone == null ? true : contains(
        data.aws_docdb_orderable_db_instance.selected[each.key].availability_zones, each.value.availability_zone
      )
      error_message = "The selected engine and instance class are unavailable in the requested Availability Zone."
    }
  }
}
