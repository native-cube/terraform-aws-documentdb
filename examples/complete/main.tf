terraform {
  required_version = ">= 1.11.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.63.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "documentdb" {
  source                    = "../.."
  name                      = var.name
  engine_version            = var.engine_version
  instance_class            = var.instance_class
  vpc_id                    = var.vpc_id
  subnet_ids                = var.subnet_ids
  final_snapshot_identifier = var.final_snapshot_identifier
  ingress_rules = {
    application = { description = "Application database access", referenced_security_group_id = var.application_security_group_id }
  }
  tags         = { Environment = "example" }
  storage_type = "iopt1"
  kms_key_id   = var.kms_key_arn
  instances = {
    writer = { promotion_tier = 0 }
    reader = { promotion_tier = 1 }
  }
  enable_performance_insights     = true
  performance_insights_kms_key_id = var.kms_key_arn
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
  cloudwatch_log_group_kms_key_id = var.log_kms_key_arn
  cluster_parameter_group = {
    family = var.parameter_group_family
    parameters = [
      { name = "tls", value = "enabled", apply_method = "pending-reboot" },
      { name = "audit_logs", value = "enabled" },
      { name = "profiler", value = "enabled" }
    ]
  }
  event_subscriptions = {
    cluster = {
      sns_topic_arn      = var.sns_topic_arn
      use_cluster_source = true
      event_categories   = ["failure", "failover", "maintenance"]
    }
  }
  snapshots = { release = { db_cluster_snapshot_identifier = var.release_snapshot_identifier } }
}
