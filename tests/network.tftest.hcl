mock_provider "aws" {
  override_during = plan
  mock_data "aws_subnet" {
    defaults = {
      vpc_id            = "vpc-0123456789abcdef0"
      availability_zone = "eu-west-1a"
      ipv6_cidr_block   = "2001:db8:1::/64"
    }
  }
  mock_data "aws_security_group" {
    defaults = { vpc_id = "vpc-0123456789abcdef0" }
  }
  mock_data "aws_db_subnet_group" {
    defaults = {
      vpc_id                  = "vpc-0123456789abcdef0"
      supported_network_types = ["IPV4", "DUAL"]
    }
  }
  mock_data "aws_docdb_engine_version" {
    defaults = {
      version                = "5.0.0"
      exportable_log_types   = ["audit", "profiler"]
      parameter_group_family = "docdb5.0"
    }
  }
  mock_data "aws_docdb_orderable_db_instance" {
    defaults = { availability_zones = ["eu-west-1a", "eu-west-1b"] }
  }
}

variables {
  name                      = "network-docdb"
  engine_version            = "5.0.0"
  final_snapshot_identifier = "network-docdb-final-v1"
  vpc_id                    = "vpc-0123456789abcdef0"
  subnet_ids                = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
}

run "validated_dual_stack_and_engine" {
  command = plan
  override_data {
    target = data.aws_subnet.selected["1"]
    values = { availability_zone = "eu-west-1b", vpc_id = "vpc-0123456789abcdef0", ipv6_cidr_block = "2001:db8:2::/64" }
  }
  variables {
    network_type                    = "DUAL"
    enabled_cloudwatch_logs_exports = ["audit"]
    cluster_parameter_group         = { family = "docdb5.0" }
    instances                       = { one = { availability_zone = "eu-west-1a" } }
  }
  assert {
    condition     = aws_docdb_cluster.main[0].network_type == "DUAL"
    error_message = "Valid dual-stack network and regional engine settings must plan."
  }
}

run "reject_one_availability_zone" {
  command         = plan
  expect_failures = [aws_docdb_subnet_group.main]
}

run "reject_cross_vpc_subnet" {
  command = plan
  override_data {
    target = data.aws_subnet.selected["1"]
    values = { vpc_id = "vpc-0fedcba9876543210", availability_zone = "eu-west-1b" }
  }
  expect_failures = [data.aws_subnet.selected["1"]]
}

run "reject_ipv4_subnet_for_dual" {
  command = plan
  variables {
    network_type = "DUAL"
  }
  override_data {
    target = data.aws_subnet.selected["1"]
    values = { ipv6_cidr_block = "", availability_zone = "eu-west-1b", vpc_id = "vpc-0123456789abcdef0" }
  }
  expect_failures = [data.aws_subnet.selected["1"]]
}

run "validate_existing_network" {
  command = plan
  variables {
    subnet_ids             = []
    create_db_subnet_group = false
    db_subnet_group_name   = "existing"
    create_security_group  = false
    security_group_ids     = ["sg-0123456789abcdef0"]
  }
  assert {
    condition     = length(data.aws_db_subnet_group.existing) == 1 && length(data.aws_security_group.selected) == 1
    error_message = "Existing network resources must be inspected."
  }
}

run "reject_existing_security_group_vpc" {
  command = plan
  variables {
    subnet_ids             = []
    create_db_subnet_group = false
    db_subnet_group_name   = "existing"
    create_security_group  = false
    security_group_ids     = ["sg-0123456789abcdef0"]
  }
  override_data {
    target = data.aws_security_group.selected["0"]
    values = { vpc_id = "vpc-0fedcba9876543210" }
  }
  expect_failures = [data.aws_security_group.selected["0"]]
}

run "reject_engine_parameter_family" {
  command = plan
  variables {
    validate_network_configuration = false
    cluster_parameter_group        = { family = "docdb4.0" }
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "reject_unavailable_instance_az" {
  command = plan
  variables {
    validate_network_configuration = false
    instances                      = { one = { availability_zone = "eu-west-1c" } }
  }
  expect_failures = [aws_docdb_cluster_instance.main]
}
