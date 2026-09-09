resource "aws_docdb_cluster_parameter_group" "main" {
  count = local.create_docdb && var.cluster_parameter_group != null ? 1 : 0

  region      = var.region
  name        = var.cluster_parameter_group.use_name_prefix ? null : coalesce(var.cluster_parameter_group.name, "${var.name}-documentdb")
  name_prefix = var.cluster_parameter_group.use_name_prefix ? "${coalesce(var.cluster_parameter_group.name, "${var.name}-documentdb")}-" : null
  description = coalesce(var.cluster_parameter_group.description, "DocumentDB parameters for ${var.name}")
  family      = var.cluster_parameter_group.family
  tags        = merge(local.common_tags, var.cluster_parameter_group.tags)

  dynamic "parameter" {
    for_each = var.cluster_parameter_group.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
