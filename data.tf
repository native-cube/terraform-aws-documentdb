data "aws_subnet" "selected" {
  for_each = local.validate_network ? { for index, id in var.subnet_ids : tostring(index) => id } : {}

  region = var.region
  id     = each.value

  lifecycle {
    postcondition {
      condition     = var.vpc_id == null || self.vpc_id == var.vpc_id
      error_message = "All supplied subnets must belong to vpc_id."
    }
    postcondition {
      condition     = var.network_type != "DUAL" || try(length(self.ipv6_cidr_block) > 0, false)
      error_message = "DUAL networking requires an IPv6 CIDR on every supplied subnet."
    }
  }
}

data "aws_security_group" "selected" {
  for_each = local.validate_network ? { for index, id in var.security_group_ids : tostring(index) => id } : {}

  region = var.region
  id     = each.value

  lifecycle {
    postcondition {
      condition = (var.vpc_id == null || self.vpc_id == var.vpc_id) && (length(var.subnet_ids) == 0 || contains(local.subnet_vpc_ids, self.vpc_id)) && (
        local.create_docdb && !var.create_db_subnet_group ? self.vpc_id == data.aws_db_subnet_group.existing[0].vpc_id : true
      )
      error_message = "Existing security groups must belong to the selected database VPC."
    }
  }
}

data "aws_db_subnet_group" "existing" {
  count = local.validate_network && local.create_docdb && !var.create_db_subnet_group ? 1 : 0

  region = var.region
  name   = var.db_subnet_group_name

  lifecycle {
    postcondition {
      condition     = var.vpc_id == null || self.vpc_id == var.vpc_id
      error_message = "The existing subnet group must belong to vpc_id."
    }
    postcondition {
      condition     = contains(self.supported_network_types, var.network_type)
      error_message = "The existing subnet group does not support the selected network_type."
    }
  }
}

data "aws_docdb_engine_version" "selected" {
  count = local.validate_engine ? 1 : 0

  region  = var.region
  engine  = var.engine
  version = var.engine_version
}

data "aws_docdb_orderable_db_instance" "selected" {
  for_each = local.validate_engine ? local.instances : {}

  region         = var.region
  engine         = var.engine
  engine_version = data.aws_docdb_engine_version.selected[0].version
  instance_class = local.instance_classes[each.key]
  vpc            = true
}
