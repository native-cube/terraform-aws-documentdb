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
  alias  = "primary"
  region = var.primary_region
}
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}
module "primary" {
  source                      = "../.."
  providers                   = { aws = aws.primary }
  name                        = "${var.name}-primary"
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  create_global_cluster       = true
  global_cluster_identifier   = var.name
  manage_master_user_password = false
  master_password_wo          = var.master_password_wo
  master_password_wo_version  = var.master_password_wo_version
  vpc_id                      = var.primary_vpc_id
  subnet_ids                  = var.primary_subnet_ids
  kms_key_id                  = var.primary_kms_key_arn
  final_snapshot_identifier   = var.primary_final_snapshot_identifier
  instances                   = { writer = {}, reader = { promotion_tier = 1 } }
  ingress_rules               = { application = { referenced_security_group_id = var.primary_application_security_group_id } }
}
module "secondary" {
  source                    = "../.."
  providers                 = { aws = aws.secondary }
  name                      = "${var.name}-secondary"
  engine_version            = var.engine_version
  instance_class            = var.instance_class
  is_primary_cluster        = false
  global_cluster_identifier = module.primary.global_cluster_id
  vpc_id                    = var.secondary_vpc_id
  subnet_ids                = var.secondary_subnet_ids
  kms_key_id                = var.secondary_kms_key_arn
  final_snapshot_identifier = var.secondary_final_snapshot_identifier
  ingress_rules             = { application = { referenced_security_group_id = var.secondary_application_security_group_id } }
  # The global container alone is insufficient: the primary compute must be ready.
  depends_on = [module.primary]
}
