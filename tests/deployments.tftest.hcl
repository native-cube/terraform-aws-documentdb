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
run "production_defaults" {
  command = plan
  assert {
    condition     = aws_docdb_cluster.main[0].storage_encrypted && aws_docdb_cluster.main[0].deletion_protection && !aws_docdb_cluster.main[0].skip_final_snapshot && aws_docdb_cluster.main[0].backup_retention_period == 7 && aws_docdb_cluster.main[0].manage_master_user_password == true && length(aws_docdb_cluster_instance.main) == 1 && length(aws_vpc_security_group_ingress_rule.main) == 0 && length(aws_vpc_security_group_egress_rule.main) == 0
    error_message = "production_defaults"
  }
}

run "disabled_creates_nothing" {
  command = plan
  variables {
    create = false
  }
  assert {
    condition     = length(aws_docdb_cluster.main) == 0 && length(aws_docdb_cluster_instance.main) == 0 && length(aws_security_group.main) == 0 && output.cluster_endpoint == null && length(output.security_group_ids) == 0
    error_message = "disabled_creates_nothing"
  }
}

run "mixed_serverless_compute" {
  command = plan
  variables {
    serverless_v2_scaling_configuration = { min_capacity = 0.5, max_capacity = 32 }
    instances                           = { writer = { instance_class = "db.serverless" }, reader = { instance_class = "db.r6g.large", promotion_tier = 2 } }
    storage_type                        = "iopt1"
    network_type                        = "DUAL"
  }
  assert {
    condition     = aws_docdb_cluster_instance.main["writer"].instance_class == "db.serverless" && aws_docdb_cluster_instance.main["reader"].promotion_tier == 2 && aws_docdb_cluster.main[0].serverless_v2_scaling_configuration[0].max_capacity == 32 && aws_docdb_cluster.main[0].network_type == "DUAL" && aws_docdb_cluster.main[0].storage_type == "iopt1"
    error_message = "mixed_serverless_compute"
  }
}

run "write_only_credentials" {
  command = plan
  variables {
    manage_master_user_password = false
    master_password_wo          = "MockPassword123!"
    master_password_wo_version  = 2
  }
  assert {
    condition     = aws_docdb_cluster.main[0].master_password_wo_version == 2 && aws_docdb_cluster.main[0].master_password == null && aws_docdb_cluster.main[0].manage_master_user_password == null
    error_message = "write_only_credentials"
  }
}

run "legacy_credentials" {
  command = plan
  variables {
    manage_master_user_password = false
    master_password             = "MockPassword123!"
  }
  assert {
    condition     = aws_docdb_cluster.main[0].manage_master_user_password == null
    error_message = "legacy_credentials"
  }
}

run "global_primary" {
  command = plan
  variables {
    create_global_cluster       = true
    engine_version              = "5.0.0"
    manage_master_user_password = false
    master_password_wo          = "MockPassword123!"
    master_password_wo_version  = 1
  }
  assert {
    condition     = length(aws_docdb_global_cluster.main) == 1 && aws_docdb_global_cluster.main[0].engine == "docdb" && aws_docdb_global_cluster.main[0].storage_encrypted && aws_docdb_cluster.main[0].global_cluster_identifier == "test-docdb-global"
    error_message = "global_primary"
  }
}

run "global_secondary_omits_credentials" {
  command = plan
  variables {
    is_primary_cluster        = false
    global_cluster_identifier = "existing-global"
  }
  assert {
    condition     = aws_docdb_cluster.main[0].master_password == null && aws_docdb_cluster.main[0].master_password_wo_version == null && aws_docdb_cluster.main[0].manage_master_user_password == null
    error_message = "global_secondary_omits_credentials"
  }
}

run "global_from_existing_omits_inherited_settings" {
  command = plan
  variables {
    create_cluster                              = false
    create_global_cluster                       = true
    global_cluster_source_db_cluster_identifier = "arn:aws:rds:eu-west-1:123456789012:cluster:existing"
    engine_version                              = "5.0.0"
    global_cluster_database_name                = "inherited"
  }
  assert {
    condition     = length(aws_docdb_cluster.main) == 0 && length(aws_security_group.main) == 0 && aws_docdb_global_cluster.main[0].database_name == null
    error_message = "global_from_existing_omits_inherited_settings"
  }
}

run "snapshot_restore_inherits_credentials" {
  command = plan
  variables {
    snapshot_identifier = "existing-backup"
  }
  assert {
    condition     = aws_docdb_cluster.main[0].snapshot_identifier == "existing-backup" && aws_docdb_cluster.main[0].manage_master_user_password == null && aws_docdb_cluster.main[0].master_password_wo_version == null
    error_message = "snapshot_restore_inherits_credentials"
  }
}

run "point_in_time_latest" {
  command = plan
  variables {
    restore_to_point_in_time = { source_cluster_identifier = "source", use_latest_restorable_time = true }
  }
  assert {
    condition     = aws_docdb_cluster.main[0].restore_to_point_in_time[0].use_latest_restorable_time && aws_docdb_cluster.main[0].master_password == null
    error_message = "point_in_time_latest"
  }
}

run "point_in_time_timestamp" {
  command = plan
  variables {
    restore_to_point_in_time = { source_cluster_identifier = "source", restore_to_time = "2026-09-01T12:00:00Z", restore_type = "copy-on-write" }
  }
  assert {
    condition     = aws_docdb_cluster.main[0].restore_to_point_in_time[0].restore_to_time == "2026-09-01T12:00:00Z"
    error_message = "point_in_time_timestamp"
  }
}

run "existing_network_and_parameters" {
  command = plan
  variables {
    create_db_subnet_group          = false
    db_subnet_group_name            = "existing-subnets"
    create_security_group           = false
    security_group_ids              = ["sg-0123456789abcdef0"]
    db_cluster_parameter_group_name = "existing-parameters"
  }
  assert {
    condition     = length(aws_docdb_subnet_group.main) == 0 && length(aws_security_group.main) == 0 && aws_docdb_cluster.main[0].db_subnet_group_name == "existing-subnets" && aws_docdb_cluster.main[0].db_cluster_parameter_group_name == "existing-parameters"
    error_message = "existing_network_and_parameters"
  }
}

run "logging_and_event_delivery" {
  command = plan
  variables {
    enabled_cloudwatch_logs_exports = ["audit", "profiler"]
    cluster_parameter_group         = { family = "docdb5.0", parameters = [{ name = "audit_logs", value = "enabled" }, { name = "profiler", value = "enabled" }] }
    event_subscriptions             = { cluster = { sns_topic_arn = "arn:aws:sns:eu-west-1:123456789012:docdb", use_cluster_source = true } }
    snapshots                       = { release = { db_cluster_snapshot_identifier = "test-release-v1" } }
  }
  assert {
    condition     = aws_cloudwatch_log_group.main["audit"].name == "/aws/docdb/test-docdb/audit" && length(aws_cloudwatch_log_group.main) == 2 && aws_docdb_event_subscription.main["cluster"].source_type == "db-cluster" && aws_docdb_event_subscription.main["cluster"].source_ids == toset(["test-docdb"]) && aws_docdb_cluster_snapshot.main["release"].db_cluster_identifier == "test-docdb"
    error_message = "logging_and_event_delivery"
  }
}

run "instance_overrides" {
  command = plan
  variables {
    enable_performance_insights = true
    instances                   = { custom = { identifier_prefix = "custom-", instance_class = "db.r8g.large", apply_immediately = true, auto_minor_version_upgrade = false, copy_tags_to_snapshot = false, ca_cert_identifier = "rds-ca-rsa2048-g1", certificate_rotation_restart = false, performance_insights_kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/00000000-0000-0000-0000-000000000001", preferred_maintenance_window = "sun:04:00-sun:04:30", timeouts = { create = "150m" } } }
  }
  assert {
    condition     = aws_docdb_cluster_instance.main["custom"].identifier_prefix == "custom-" && aws_docdb_cluster_instance.main["custom"].apply_immediately && !aws_docdb_cluster_instance.main["custom"].auto_minor_version_upgrade && !aws_docdb_cluster_instance.main["custom"].certificate_rotation_restart && aws_docdb_cluster_instance.main["custom"].timeouts.create == "150m"
    error_message = "instance_overrides"
  }
}

run "security_rule_variants" {
  command = plan
  variables {
    ingress_rules = {
      app    = { referenced_security_group_id = "sg-0123456789abcdef0" }
      ipv6   = { cidr_ipv6 = "2001:db8::/64" }
      prefix = { prefix_list_id = "pl-0123456789abcdef0", from_port = 27018, to_port = 27018 }
    }
    egress_rules = { all = { cidr_ipv4 = "10.0.0.0/16", ip_protocol = "-1" } }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.main["app"].from_port == 27017 && aws_vpc_security_group_ingress_rule.main["prefix"].from_port == 27018 && aws_vpc_security_group_egress_rule.main["all"].from_port == null
    error_message = "security_rule_variants"
  }
}

run "elastic_1_instances_per_shard" {
  command = plan
  variables {
    cluster_type                = "elastic"
    elastic_cluster             = { shard_capacity = 4, shard_count = 2, shard_instance_count = 1 }
    elastic_admin_user_password = "MockPassword123!"
  }
  assert {
    condition     = length(aws_docdbelastic_cluster.main) == 1 && length(aws_docdb_cluster.main) == 0 && length(aws_docdb_cluster_instance.main) == 0 && length(aws_docdb_subnet_group.main) == 0 && aws_docdbelastic_cluster.main[0].shard_instance_count == 1 && aws_docdbelastic_cluster.main[0].backup_retention_period == 7
    error_message = "elastic_1_instances_per_shard"
  }
}

run "elastic_16_instances_per_shard" {
  command = plan
  variables {
    cluster_type                = "elastic"
    elastic_cluster             = { shard_capacity = 4, shard_count = 2, shard_instance_count = 16 }
    elastic_admin_user_password = "MockPassword123!"
  }
  assert {
    condition     = length(aws_docdbelastic_cluster.main) == 1 && length(aws_docdb_cluster.main) == 0 && length(aws_docdb_cluster_instance.main) == 0 && length(aws_docdb_subnet_group.main) == 0 && aws_docdbelastic_cluster.main[0].shard_instance_count == 16 && aws_docdbelastic_cluster.main[0].backup_retention_period == 7
    error_message = "elastic_16_instances_per_shard"
  }
}
