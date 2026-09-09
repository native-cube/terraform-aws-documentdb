mock_provider "aws" {
  override_during = plan
  mock_resource "aws_docdb_cluster_instance" {
    # This optional/computed attribute is filled by the provider when omitted.
    defaults = { performance_insights_kms_key_id = "provider-computed-key" }
  }
}

variables {
  name                            = "insights-docdb"
  final_snapshot_identifier       = "insights-docdb-final-v1"
  vpc_id                          = "vpc-0123456789abcdef0"
  subnet_ids                      = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  validate_network_configuration  = false
  validate_engine_capabilities    = false
  enable_performance_insights     = true
  performance_insights_kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/00000000-0000-0000-0000-000000000001"
}

run "instance_can_disable_insights_with_shared_key" {
  command = plan
  variables {
    instances = {
      enabled  = {}
      disabled = { enable_performance_insights = false }
      custom = {
        performance_insights_kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/00000000-0000-0000-0000-000000000002"
      }
    }
  }
  assert {
    condition = (
      !aws_docdb_cluster_instance.main["disabled"].enable_performance_insights &&
      aws_docdb_cluster_instance.main["disabled"].performance_insights_kms_key_id == "provider-computed-key" &&
      aws_docdb_cluster_instance.main["enabled"].performance_insights_kms_key_id == var.performance_insights_kms_key_id &&
      aws_docdb_cluster_instance.main["custom"].performance_insights_kms_key_id == var.instances["custom"].performance_insights_kms_key_id
    )
    error_message = "Disabled instances must omit the shared key; enabled instances must retain shared or explicit overrides."
  }
}

run "instance_can_enable_insights_when_default_is_disabled" {
  command = plan
  variables {
    enable_performance_insights = false
    instances = {
      enabled  = { enable_performance_insights = true }
      disabled = {}
    }
  }
  assert {
    condition = (
      aws_docdb_cluster_instance.main["enabled"].enable_performance_insights &&
      aws_docdb_cluster_instance.main["enabled"].performance_insights_kms_key_id == var.performance_insights_kms_key_id &&
      aws_docdb_cluster_instance.main["disabled"].performance_insights_kms_key_id == "provider-computed-key"
    )
    error_message = "Per-instance opt-in must still use the shared key while other instances omit it."
  }
}

run "reject_explicit_instance_key_when_insights_disabled" {
  command = plan
  variables {
    instances = {
      disabled = {
        enable_performance_insights     = false
        performance_insights_kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/00000000-0000-0000-0000-000000000002"
      }
    }
  }
  expect_failures = [aws_docdb_cluster_instance.main]
}
