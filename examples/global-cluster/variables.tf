variable "name" {
  description = "Global database name."
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
variable "primary_region" {
  description = "Primary AWS Region."
  type        = string
}
variable "primary_vpc_id" {
  description = "Primary Existing VPC ID."
  type        = string
}
variable "primary_subnet_ids" {
  description = "Primary Private subnets spanning two or more Availability Zones."
  type        = list(string)
}
variable "primary_kms_key_arn" {
  description = "Primary Existing regional encryption key ARN."
  type        = string
}
variable "primary_final_snapshot_identifier" {
  description = "Primary Unique final snapshot name."
  type        = string
}
variable "primary_application_security_group_id" {
  description = "Primary Existing regional application security group."
  type        = string
}
variable "secondary_region" {
  description = "Secondary AWS Region."
  type        = string
}
variable "secondary_vpc_id" {
  description = "Secondary Existing VPC ID."
  type        = string
}
variable "secondary_subnet_ids" {
  description = "Secondary Private subnets spanning two or more Availability Zones."
  type        = list(string)
}
variable "secondary_kms_key_arn" {
  description = "Secondary Existing regional encryption key ARN."
  type        = string
}
variable "secondary_final_snapshot_identifier" {
  description = "Secondary Unique final snapshot name."
  type        = string
}
variable "secondary_application_security_group_id" {
  description = "Secondary Existing regional application security group."
  type        = string
}
variable "master_password_wo" {
  description = "Ephemeral primary password; global databases do not support managed passwords."
  type        = string
  sensitive   = true
  ephemeral   = true
}
variable "master_password_wo_version" {
  description = "Increment whenever the primary write-only password changes."
  type        = number
  default     = 1
}
