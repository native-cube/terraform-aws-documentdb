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
variable "engine_version" {
  description = "Supported regional DocumentDB engine version; set explicitly."
  type        = string
}
variable "instance_class" {
  description = "Supported instance class."
  type        = string
  default     = "db.r6g.large"
}
variable "final_snapshot_identifier" {
  description = "Unique snapshot name reserved for final cluster deletion."
  type        = string
}
variable "kms_key_arn" {
  description = "Existing database and Performance Insights encryption key ARN."
  type        = string
}
variable "log_kms_key_arn" {
  description = "Existing log encryption key ARN with a policy allowing CloudWatch Logs."
  type        = string
}
variable "parameter_group_family" {
  description = "Parameter group family matching engine_version, such as docdb5.0 or docdb8.0."
  type        = string
}
variable "sns_topic_arn" {
  description = "Existing SNS topic ARN with permissions for DocumentDB events."
  type        = string
}
variable "release_snapshot_identifier" {
  description = "Unique one-time release snapshot name."
  type        = string
}
