resource "aws_cloudwatch_log_group" "main" {
  for_each = local.create_docdb && var.create_cloudwatch_log_groups ? var.enabled_cloudwatch_logs_exports : toset([])

  region                      = var.region
  name                        = "/aws/docdb/${var.name}/${each.value}"
  retention_in_days           = var.cloudwatch_log_group_retention_in_days
  kms_key_id                  = var.cloudwatch_log_group_kms_key_id
  log_group_class             = var.cloudwatch_log_group_class
  deletion_protection_enabled = var.cloudwatch_log_group_deletion_protection
  skip_destroy                = var.cloudwatch_log_group_skip_destroy
  tags                        = local.common_tags

  lifecycle {
    precondition {
      condition     = var.cluster_identifier_prefix == null
      error_message = "Pre-created export log groups require a deterministic cluster name. Omit cluster_identifier_prefix or set create_cloudwatch_log_groups = false."
    }
  }
}

resource "aws_docdb_event_subscription" "main" {
  for_each = var.create ? var.event_subscriptions : {}

  region           = var.region
  name             = each.value.name_prefix == null ? coalesce(each.value.name, "${var.name}-${each.key}") : null
  name_prefix      = each.value.name_prefix
  sns_topic_arn    = each.value.sns_topic_arn
  enabled          = each.value.enabled
  event_categories = each.value.event_categories
  source_type      = each.value.use_cluster_source ? "db-cluster" : each.value.source_type
  source_ids       = each.value.use_cluster_source ? [try(aws_docdb_cluster.main[0].cluster_identifier, null)] : each.value.source_ids
  tags             = merge(local.common_tags, each.value.tags)

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = !each.value.use_cluster_source || local.create_docdb
      error_message = "use_cluster_source requires an instance-based cluster managed by this module."
    }
  }
}
