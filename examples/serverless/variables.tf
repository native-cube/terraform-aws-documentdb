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
  description = "Regional engine version supporting DocumentDB Serverless."
  type        = string
}
variable "final_snapshot_identifier" {
  description = "Unique snapshot name reserved for final cluster deletion."
  type        = string
}
