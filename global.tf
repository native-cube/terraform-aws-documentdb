resource "aws_docdb_global_cluster" "main" {
  count = local.create_global ? 1 : 0

  region                       = var.region
  global_cluster_identifier    = coalesce(var.global_cluster_identifier, "${var.name}-global")
  source_db_cluster_identifier = var.global_cluster_source_db_cluster_identifier
  engine                       = var.global_cluster_source_db_cluster_identifier == null ? var.engine : null
  engine_version               = var.global_cluster_source_db_cluster_identifier == null ? var.engine_version : null
  database_name                = var.global_cluster_source_db_cluster_identifier == null ? var.global_cluster_database_name : null
  storage_encrypted            = var.global_cluster_source_db_cluster_identifier == null ? var.storage_encrypted : null
  deletion_protection          = var.global_cluster_deletion_protection

  dynamic "timeouts" {
    for_each = var.global_cluster_timeouts == null ? [] : [var.global_cluster_timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = var.cluster_type == "instance"
      error_message = "Elastic clusters cannot join DocumentDB global databases."
    }
    precondition {
      condition     = var.global_cluster_source_db_cluster_identifier == null || !var.create_cluster
      error_message = "Set create_cluster = false when creating a global container from an existing primary ARN."
    }
  }
}
