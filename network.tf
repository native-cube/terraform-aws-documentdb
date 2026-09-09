resource "aws_docdb_subnet_group" "main" {
  count = local.create_subnet_group ? 1 : 0

  region      = var.region
  name        = var.db_subnet_group_use_name_prefix ? null : coalesce(var.db_subnet_group_name, "${var.name}-documentdb")
  name_prefix = var.db_subnet_group_use_name_prefix ? "${coalesce(var.db_subnet_group_name, "${var.name}-documentdb")}-" : null
  description = var.db_subnet_group_description
  subnet_ids  = var.subnet_ids
  tags        = local.common_tags

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = length(var.subnet_ids) >= 2
      error_message = "A subnet group requires at least two subnets in distinct Availability Zones."
    }
    precondition {
      condition     = !local.validate_network || (length(local.subnet_vpc_ids) == 1 && length(local.subnet_azs) >= 2)
      error_message = "Database subnets must share a VPC and span at least two Availability Zones."
    }
  }
}

resource "aws_security_group" "main" {
  count = local.create_security_group ? 1 : 0

  region                 = var.region
  name                   = var.security_group_use_name_prefix ? null : coalesce(var.security_group_name, "${var.name}-documentdb")
  name_prefix            = var.security_group_use_name_prefix ? "${coalesce(var.security_group_name, "${var.name}-documentdb")}-" : null
  description            = var.security_group_description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete
  tags                   = local.common_tags

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = try(length(trimspace(var.vpc_id)) > 0, false)
      error_message = "vpc_id is required when creating a security group."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  for_each = local.create_security_group ? var.ingress_rules : {}

  region                       = var.region
  security_group_id            = aws_security_group.main[0].id
  description                  = each.value.description
  ip_protocol                  = each.value.ip_protocol
  from_port                    = contains(["tcp", "udp", "6", "17"], each.value.ip_protocol) ? coalesce(each.value.from_port, var.port) : each.value.from_port
  to_port                      = contains(["tcp", "udp", "6", "17"], each.value.ip_protocol) ? coalesce(each.value.to_port, var.port) : each.value.to_port
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
  tags                         = merge(local.common_tags, each.value.tags)
}

resource "aws_vpc_security_group_egress_rule" "main" {
  for_each = local.create_security_group ? var.egress_rules : {}

  region                       = var.region
  security_group_id            = aws_security_group.main[0].id
  description                  = each.value.description
  ip_protocol                  = each.value.ip_protocol
  from_port                    = contains(["tcp", "udp", "6", "17"], each.value.ip_protocol) ? coalesce(each.value.from_port, var.port) : each.value.from_port
  to_port                      = contains(["tcp", "udp", "6", "17"], each.value.ip_protocol) ? coalesce(each.value.to_port, var.port) : each.value.to_port
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
  tags                         = merge(local.common_tags, each.value.tags)
}
