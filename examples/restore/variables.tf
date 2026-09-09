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

  validation {
    condition     = (var.snapshot_identifier != null) != (var.restore_to_point_in_time != null)
    error_message = "Specify exactly one of snapshot_identifier or restore_to_point_in_time for this restore example."
  }

  validation {
    condition     = var.snapshot_identifier == null ? true : trimspace(var.snapshot_identifier) != ""
    error_message = "snapshot_identifier must be a non-empty snapshot name or ARN when provided."
  }
}
variable "restore_to_point_in_time" {
  description = "PITR configuration; set exactly one time selector."
  type        = object({ source_cluster_identifier = string, restore_type = optional(string, "full-copy"), restore_to_time = optional(string), use_latest_restorable_time = optional(bool, false) })
  default     = null
}

variable "manage_credentials_after_restore" {
  description = "Enable only after restoration completes to manage the restored primary's password."
  type        = bool
  default     = false
}

variable "manage_master_user_password" {
  description = "When managing credentials after restoration, let DocumentDB manage the password in Secrets Manager."
  type        = bool
  default     = true
}

variable "master_password_wo" {
  description = "Ephemeral caller-managed password for a restored primary. Requires credential management enabled and managed passwords disabled."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "master_password_wo_version" {
  description = "Positive rotation version; increment whenever master_password_wo changes."
  type        = number
  default     = null
}
