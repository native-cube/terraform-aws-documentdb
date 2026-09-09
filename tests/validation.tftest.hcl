mock_provider "aws" {
  override_during = plan
}
variables {
  name                           = "test-docdb"
  final_snapshot_identifier      = "test-docdb-final-v1"
  vpc_id                         = "vpc-0123456789abcdef0"
  subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  validate_network_configuration = false
  validate_engine_capabilities   = false
}
run "missing_final_snapshot" {
  command = plan
  variables {
    final_snapshot_identifier = null
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "kms_without_encryption" {
  command = plan
  variables {
    kms_key_id        = "arn:aws:kms:eu-west-1:123456789012:key/00000000-0000-0000-0000-000000000001"
    storage_encrypted = false
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "restore_conflict" {
  command = plan
  variables {
    snapshot_identifier      = "backup"
    restore_to_point_in_time = { source_cluster_identifier = "source", use_latest_restorable_time = true }
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "restore_without_time" {
  command = plan
  variables {
    restore_to_point_in_time = { source_cluster_identifier = "source" }
  }
  expect_failures = [var.restore_to_point_in_time]
}

run "restore_both_times" {
  command = plan
  variables {
    restore_to_point_in_time = { source_cluster_identifier = "source", restore_to_time = "2026-09-01T12:00:00Z", use_latest_restorable_time = true }
  }
  expect_failures = [var.restore_to_point_in_time]
}

run "serverless_without_capacity" {
  command = plan
  variables {
    instance_class = "db.serverless"
  }
  expect_failures = [aws_docdb_cluster_instance.main]
}

run "invalid_serverless_range" {
  command = plan
  variables {
    serverless_v2_scaling_configuration = { min_capacity = 10, max_capacity = 4 }
  }
  expect_failures = [var.serverless_v2_scaling_configuration]
}

run "invalid_serverless_increment" {
  command = plan
  variables {
    serverless_v2_scaling_configuration = { min_capacity = 0.75, max_capacity = 4 }
  }
  expect_failures = [var.serverless_v2_scaling_configuration]
}

run "global_managed_password" {
  command = plan
  variables {
    create_global_cluster = true
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "secondary_without_global" {
  command = plan
  variables {
    is_primary_cluster = false
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "primary_missing_credentials" {
  command = plan
  variables {
    manage_master_user_password = false
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "subnet_group_missing_subnets" {
  command = plan
  variables {
    subnet_ids = []
  }
  expect_failures = [aws_docdb_subnet_group.main]
}

run "missing_security_groups" {
  command = plan
  variables {
    create_security_group = false
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "ambiguous_ingress" {
  command = plan
  variables {
    ingress_rules = { bad = { cidr_ipv4 = "10.0.0.0/8", referenced_security_group_id = "sg-0123456789abcdef0" } }
  }
  expect_failures = [var.ingress_rules]
}

run "ambiguous_parameters" {
  command = plan
  variables {
    db_cluster_parameter_group_name = "existing"
    cluster_parameter_group         = { family = "docdb5.0" }
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "invalid_promotion_tier" {
  command = plan
  variables {
    instances = { one = { promotion_tier = 16 } }
  }
  expect_failures = [var.instances]
}

run "two_cluster_storage_azs" {
  command = plan
  variables {
    availability_zones = ["eu-west-1a", "eu-west-1b"]
  }
  expect_failures = [var.availability_zones]
}

run "invalid_backup_retention" {
  command = plan
  variables {
    backup_retention_period = 36
  }
  expect_failures = [var.backup_retention_period]
}

run "prefix_with_managed_logs" {
  command = plan
  variables {
    cluster_identifier_prefix       = "generated-"
    enabled_cloudwatch_logs_exports = ["audit"]
  }
  expect_failures = [aws_cloudwatch_log_group.main]
}

run "source_container_with_regional_cluster" {
  command = plan
  variables {
    create_global_cluster                       = true
    manage_master_user_password                 = false
    master_password                             = "MockPassword123!"
    global_cluster_source_db_cluster_identifier = "arn:aws:rds:eu-west-1:123456789012:cluster:existing"
  }
  expect_failures = [aws_docdb_global_cluster.main]
}

run "elastic_with_instance_restore" {
  command = plan
  variables {
    cluster_type                = "elastic"
    elastic_cluster             = { shard_capacity = 2, shard_count = 1 }
    elastic_admin_user_password = "MockPassword123!"
    snapshot_identifier         = "backup"
  }
  expect_failures = [aws_docdbelastic_cluster.main]
}
