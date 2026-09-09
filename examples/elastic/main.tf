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
  source       = "../.."
  name         = var.name
  cluster_type = "elastic"
  vpc_id       = var.vpc_id
  subnet_ids   = var.subnet_ids
  kms_key_id   = var.kms_key_arn
  elastic_cluster = {
    admin_user_name      = "dbadmin"
    auth_type            = "PLAIN_TEXT"
    shard_capacity       = 2
    shard_count          = 2
    shard_instance_count = 2
  }
  elastic_admin_user_password = var.admin_user_password
  ingress_rules               = { application = { referenced_security_group_id = var.application_security_group_id } }
  tags                        = { Environment = "example" }
}
