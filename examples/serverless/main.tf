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
  instance_class            = "db.serverless"
  vpc_id                    = var.vpc_id
  subnet_ids                = var.subnet_ids
  final_snapshot_identifier = var.final_snapshot_identifier
  ingress_rules = {
    application = { description = "Application database access", referenced_security_group_id = var.application_security_group_id }
  }
  tags = { Environment = "example" }
  instances = {
    writer = {}
    reader = { promotion_tier = 1 }
  }
  serverless_v2_scaling_configuration = { min_capacity = 0.5, max_capacity = 16 }
}
