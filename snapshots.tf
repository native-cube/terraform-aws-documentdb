resource "aws_docdb_cluster_snapshot" "main" {
  for_each = var.create ? var.snapshots : {}

  region                         = var.region
  db_cluster_identifier          = each.value.db_cluster_identifier != null ? each.value.db_cluster_identifier : try(aws_docdb_cluster.main[0].cluster_identifier, null)
  db_cluster_snapshot_identifier = each.value.db_cluster_snapshot_identifier

  dynamic "timeouts" {
    for_each = each.value.create_timeout == null ? [] : [each.value.create_timeout]
    content {
      create = timeouts.value
    }
  }

  depends_on = [aws_docdb_cluster_instance.main]

  lifecycle {
    precondition {
      condition     = each.value.db_cluster_identifier != null || local.create_docdb
      error_message = "A snapshot requires a managed instance cluster or an explicit external db_cluster_identifier."
    }
  }
}
