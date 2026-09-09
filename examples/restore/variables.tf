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
variable "snapshot_identifier" {
  description = "Snapshot name or ARN; choose this or restore_to_point_in_time."
  type        = string
  default     = null
}
variable "restore_to_point_in_time" {
  description = "PITR configuration; set exactly one time selector."
  type        = object({ source_cluster_identifier = string, restore_type = optional(string, "full-copy"), restore_to_time = optional(string), use_latest_restorable_time = optional(bool, false) })
  default     = null
}
