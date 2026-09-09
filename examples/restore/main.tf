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
  tags                             = { Environment = "example" }
  snapshot_identifier              = var.snapshot_identifier
  restore_to_point_in_time         = var.restore_to_point_in_time
  manage_credentials_after_restore = var.manage_credentials_after_restore
  manage_master_user_password      = var.manage_master_user_password
  master_password_wo               = var.master_password_wo
  master_password_wo_version       = var.master_password_wo_version
}
