variable "region" {
  description = "AWS Region for the example."
  type        = string
}
variable "name" {
  description = "Unique deployment name."
  type        = string
}
variable "vpc_id" {
  description = "Existing VPC ID."
  type        = string
}
variable "subnet_ids" {
  description = "Existing private subnets in at least two Availability Zones."
  type        = list(string)
}
variable "application_security_group_id" {
  description = "Existing application security group allowed to connect."
  type        = string
}
variable "kms_key_arn" {
  description = "Existing KMS key ARN for Elastic storage."
  type        = string
}
variable "admin_user_password" {
  description = "Elastic administrator password. Stored in state because the provider has no write-only Elastic argument."
  type        = string
  sensitive   = true
}
