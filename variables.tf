variable "create" {
  description = "Whether to create module-managed resources."
  type        = bool
  default     = true
  nullable    = false
}

variable "name" {
  description = "Cluster name and default prefix for related resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.name)) && !endswith(var.name, "-") && !strcontains(var.name, "--")
    error_message = "name must be 1-63 lowercase letters, digits, or hyphens, begin with a letter, and have no trailing or consecutive hyphens."
  }
}

variable "region" {
  description = "Optional resource Region; defaults to the AWS provider Region."
  type        = string
  default     = null
}

variable "create_cluster" {
  description = "Whether to create a regional cluster. Set false for a global container or standalone event/snapshot resources."
  type        = bool
  default     = true
  nullable    = false
}

variable "cluster_type" {
  description = "Deployment type: instance (provisioned or Serverless) or elastic."
  type        = string
  default     = "instance"
  nullable    = false

  validation {
    condition     = contains(["instance", "elastic"], var.cluster_type)
    error_message = "cluster_type must be instance or elastic."
  }
}

variable "cluster_identifier_prefix" {
  description = "Optional generated cluster-name prefix instead of name. Related resource names still use name."
  type        = string
  default     = null
}

variable "engine" {
  description = "DocumentDB database engine."
  type        = string
  default     = "docdb"
  nullable    = false

  validation {
    condition     = var.engine == "docdb"
    error_message = "engine must be docdb."
  }
}

variable "engine_version" {
  description = "Engine version for instance-based and new global clusters. Null uses the AWS default; pin explicitly for controlled upgrades."
  type        = string
  default     = null
}

variable "cluster_members" {
  description = "Optional expected cluster member identifiers for provider drift detection. Membership is created through instances; normally leave null."
  type        = set(string)
  default     = null
}

variable "instance_class" {
  description = "Default instance class; any regionally supported class is accepted, including db.serverless."
  type        = string
  default     = "db.r6g.large"
  nullable    = false
}

variable "instances" {
  description = "Instance configurations keyed by stable caller-chosen keys. Empty maps permit externally managed compute; used only for instance clusters."
  type = map(object({
    identifier                      = optional(string)
    identifier_prefix               = optional(string)
    instance_class                  = optional(string)
    availability_zone               = optional(string)
    apply_immediately               = optional(bool)
    auto_minor_version_upgrade      = optional(bool)
    ca_cert_identifier              = optional(string)
    certificate_rotation_restart    = optional(bool)
    copy_tags_to_snapshot           = optional(bool)
    enable_performance_insights     = optional(bool)
    performance_insights_kms_key_id = optional(string)
    preferred_maintenance_window    = optional(string)
    promotion_tier                  = optional(number, 0)
    tags                            = optional(map(string), {})
    timeouts                        = optional(object({ create = optional(string), update = optional(string), delete = optional(string) }))
  }))
  default  = { one = {} }
  nullable = false

  validation {
    condition     = alltrue([for instance in var.instances : instance.promotion_tier >= 0 && instance.promotion_tier <= 15 && floor(instance.promotion_tier) == instance.promotion_tier && !(instance.identifier != null && instance.identifier_prefix != null)])
    error_message = "Each promotion_tier must be an integer from 0 to 15; identifier and identifier_prefix conflict."
  }
}

variable "master_username" {
  description = "Primary cluster administrator username. Omitted for restores and global secondaries."
  type        = string
  default     = "dbadmin"
  nullable    = false
}

variable "is_primary_cluster" {
  description = "Whether this is the primary cluster; false requires a global cluster identifier and omits credentials."
  type        = bool
  default     = true
  nullable    = false
}

variable "manage_master_user_password" {
  description = "Let DocumentDB manage the password in Secrets Manager. Set false for global databases or caller-managed passwords. Restored clusters inherit credentials unless manage_credentials_after_restore is enabled."
  type        = bool
  default     = true
  nullable    = false
}

variable "manage_credentials_after_restore" {
  description = "Opt in to managing a restored primary's password after restoration completes. Enable on a subsequent apply, retaining the restore input. Uses the normal managed or caller-managed password settings; the inherited username is never changed."
  type        = bool
  default     = false
  nullable    = false
}

variable "master_password" {
  description = "Optional legacy caller-managed password stored in Terraform state. Prefer master_password_wo. Conflicts with managed passwords and write-only credentials."
  type        = string
  default     = null
  sensitive   = true
}

variable "master_password_wo" {
  description = "Ephemeral write-only password; never stored in plans or state. Supply a version to trigger rotation."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "master_password_wo_version" {
  description = "Positive password rotation version. Increment whenever master_password_wo changes."
  type        = number
  default     = null

  validation {
    condition     = var.master_password_wo_version == null ? true : var.master_password_wo_version >= 1 && floor(var.master_password_wo_version) == var.master_password_wo_version
    error_message = "master_password_wo_version must be a positive integer."
  }
}

variable "port" {
  description = "Database port; Elastic supports only 27017."
  type        = number
  default     = 27017
  nullable    = false

  validation {
    condition     = var.port >= 1 && var.port <= 65535 && floor(var.port) == var.port
    error_message = "port must be an integer from 1 to 65535."
  }
}

variable "availability_zones" {
  description = "Optional cluster storage Availability Zones. Supply exactly three to avoid perpetual AWS-added AZ drift."
  type        = set(string)
  default     = null

  validation {
    condition     = var.availability_zones == null ? true : length(var.availability_zones) == 3
    error_message = "availability_zones must contain exactly three distinct AZs, or be null for AWS selection."
  }
}

variable "network_type" {
  description = "Instance cluster network stack. DUAL requires IPv6-capable subnets."
  type        = string
  default     = "IPV4"
  nullable    = false

  validation {
    condition     = contains(["IPV4", "DUAL"], var.network_type)
    error_message = "network_type must be IPV4 or DUAL."
  }
}

variable "storage_encrypted" {
  description = "Whether instance cluster storage is encrypted. Elastic always encrypts storage."
  type        = bool
  default     = true
  nullable    = false
}

variable "storage_type" {
  description = "Instance cluster storage configuration: standard or I/O-Optimized (iopt1)."
  type        = string
  default     = "standard"
  nullable    = false

  validation {
    condition     = contains(["standard", "iopt1"], var.storage_type)
    error_message = "storage_type must be standard or iopt1."
  }
}

variable "kms_key_id" {
  description = "Existing KMS key ARN for cluster storage encryption; null uses the AWS-managed key."
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Days to retain automated backups (1-35)."
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35 && floor(var.backup_retention_period) == var.backup_retention_period
    error_message = "backup_retention_period must be an integer from 1 to 35."
  }
}

variable "preferred_backup_window" {
  description = "Daily UTC backup window (hh:mm-hh:mm); null lets AWS select."
  type        = string
  default     = null
}

variable "preferred_maintenance_window" {
  description = "Weekly UTC cluster maintenance window (ddd:hh:mm-ddd:hh:mm)."
  type        = string
  default     = null
}

variable "ca_cert_identifier" {
  description = "Default instance CA certificate identifier."
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Apply modifications immediately instead of during the maintenance window."
  type        = bool
  default     = false
  nullable    = false
}

variable "allow_major_version_upgrade" {
  description = "Allow an explicit major engine version upgrade."
  type        = bool
  default     = false
  nullable    = false
}

variable "auto_minor_version_upgrade" {
  description = "Default instance automatic minor version upgrade setting."
  type        = bool
  default     = true
  nullable    = false
}

variable "certificate_rotation_restart" {
  description = "Default instance restart behavior for certificate rotation."
  type        = bool
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy instance tags to instance snapshots."
  type        = bool
  default     = true
  nullable    = false
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights on instances by default."
  type        = bool
  default     = false
  nullable    = false
}

variable "deletion_protection" {
  description = "Protect instance-based clusters from deletion."
  type        = bool
  default     = true
  nullable    = false
}

variable "skip_final_snapshot" {
  description = "Skip the final instance-cluster snapshot at deletion."
  type        = bool
  default     = false
  nullable    = false
}

variable "performance_insights_kms_key_id" {
  description = "Default existing KMS key for instances with Performance Insights enabled. Omitted for instances that disable Performance Insights."
  type        = string
  default     = null
}

variable "final_snapshot_identifier" {
  description = "Unique final snapshot name required unless skip_final_snapshot is true. Change before deleting a recreated cluster."
  type        = string
  default     = null
}

variable "snapshot_identifier" {
  description = "Existing snapshot identifier or ARN to restore; conflicts with point-in-time restore."
  type        = string
  default     = null
}

variable "restore_to_point_in_time" {
  description = "Point-in-time restore source and exactly one time selection. Credentials are inherited unless manage_credentials_after_restore is enabled after restoration."
  type = object({
    source_cluster_identifier  = string
    restore_type               = optional(string, "full-copy")
    restore_to_time            = optional(string)
    use_latest_restorable_time = optional(bool, false)
  })
  default = null

  validation {
    condition     = var.restore_to_point_in_time == null ? true : (contains(["full-copy", "copy-on-write"], var.restore_to_point_in_time.restore_type) && ((var.restore_to_point_in_time.restore_to_time != null) != var.restore_to_point_in_time.use_latest_restorable_time) && (var.restore_to_point_in_time.restore_to_time == null ? true : can(timecmp(var.restore_to_point_in_time.restore_to_time, var.restore_to_point_in_time.restore_to_time))))
    error_message = "Restore requires full-copy or copy-on-write and exactly one of an RFC3339 restore_to_time or use_latest_restorable_time = true."
  }
}

variable "serverless_v2_scaling_configuration" {
  description = "Serverless DCU range. Use db.serverless instances. Removing this block replaces the cluster."
  type        = object({ min_capacity = number, max_capacity = number })
  default     = null

  validation {
    condition     = var.serverless_v2_scaling_configuration == null ? true : (var.serverless_v2_scaling_configuration.min_capacity >= 0.5 && var.serverless_v2_scaling_configuration.max_capacity >= 1 && var.serverless_v2_scaling_configuration.max_capacity <= 256 && var.serverless_v2_scaling_configuration.min_capacity <= var.serverless_v2_scaling_configuration.max_capacity && floor(var.serverless_v2_scaling_configuration.min_capacity * 2) == var.serverless_v2_scaling_configuration.min_capacity * 2 && floor(var.serverless_v2_scaling_configuration.max_capacity * 2) == var.serverless_v2_scaling_configuration.max_capacity * 2)
    error_message = "Serverless capacity must use 0.5 DCU increments, with 0.5 <= min <= max <= 256 and max >= 1."
  }
}

variable "create_global_cluster" {
  description = "Create a DocumentDB global container."
  type        = bool
  default     = false
  nullable    = false
}

variable "global_cluster_deletion_protection" {
  description = "Protect the global container from deletion."
  type        = bool
  default     = true
  nullable    = false
}

variable "global_cluster_identifier" {
  description = "Existing global container to join, or new container name (defaults to <name>-global)."
  type        = string
  default     = null
}

variable "global_cluster_source_db_cluster_identifier" {
  description = "Existing external primary cluster ARN for creating a global container. Requires create_cluster = false to avoid circular dependencies."
  type        = string
  default     = null
}

variable "global_cluster_database_name" {
  description = "Optional provider database_name argument for a new empty global container; not used when inheriting from a source."
  type        = string
  default     = null
}

variable "create_db_subnet_group" {
  description = "Create a subnet group for an instance cluster; false requires db_subnet_group_name."
  type        = bool
  default     = true
  nullable    = false
}

variable "db_subnet_group_use_name_prefix" {
  description = "Generate a unique subnet group name using db_subnet_group_name or name as a prefix."
  type        = bool
  default     = false
  nullable    = false
}

variable "create_security_group" {
  description = "Create a security group with only explicitly declared rules."
  type        = bool
  default     = true
  nullable    = false
}

variable "security_group_use_name_prefix" {
  description = "Generate a unique security group name from its configured name."
  type        = bool
  default     = true
  nullable    = false
}

variable "revoke_rules_on_delete" {
  description = "Revoke security group rules before deleting the group."
  type        = bool
  default     = false
  nullable    = false
}

variable "validate_network_configuration" {
  description = "Read subnet/security-group metadata to check VPC, AZ, and IPv6 compatibility."
  type        = bool
  default     = true
  nullable    = false
}

variable "validate_engine_capabilities" {
  description = "Query regional engine versions and instance offerings during planning."
  type        = bool
  default     = true
  nullable    = false
}

variable "vpc_id" {
  description = "Existing VPC ID. Required when creating a security group; also used by network validation."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Existing private subnet IDs spanning at least two Availability Zones."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "security_group_ids" {
  description = "Existing VPC security groups to attach alongside the optional managed group."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "db_subnet_group_name" {
  description = "Name of an existing or module-created DocumentDB subnet group."
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "Optional name of the module-created security group."
  type        = string
  default     = null
}

variable "db_cluster_parameter_group_name" {
  description = "Existing cluster parameter group; conflicts with cluster_parameter_group."
  type        = string
  default     = null
}

variable "db_subnet_group_description" {
  description = "Description of the managed subnet group."
  type        = string
  default     = "DocumentDB subnet group"
  nullable    = false
}

variable "security_group_description" {
  description = "Description of the managed security group."
  type        = string
  default     = "DocumentDB access"
  nullable    = false
}

variable "ingress_rules" {
  description = "Explicit ingress rules keyed by stable names. TCP/UDP ports default to the database port; exactly one traffic source/destination is required."
  type = map(object({
    description                  = optional(string)
    ip_protocol                  = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for rule in var.ingress_rules : length([for source in [rule.cidr_ipv4, rule.cidr_ipv6, rule.prefix_list_id, rule.referenced_security_group_id] : source if source != null]) == 1 && (rule.ip_protocol != "-1" || (rule.from_port == null && rule.to_port == null))])
    error_message = "Each rule requires exactly one CIDR, prefix list, or security group; protocol -1 must omit ports."
  }
}

variable "egress_rules" {
  description = "Explicit egress rules keyed by stable names. TCP/UDP ports default to the database port; exactly one traffic source/destination is required."
  type = map(object({
    description                  = optional(string)
    ip_protocol                  = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for rule in var.egress_rules : length([for source in [rule.cidr_ipv4, rule.cidr_ipv6, rule.prefix_list_id, rule.referenced_security_group_id] : source if source != null]) == 1 && (rule.ip_protocol != "-1" || (rule.from_port == null && rule.to_port == null))])
    error_message = "Each rule requires exactly one CIDR, prefix list, or security group; protocol -1 must omit ports."
  }
}

variable "cluster_parameter_group" {
  description = "Optional cluster parameter group, including TLS, audit, profiler, and other engine parameters."
  type = object({
    name            = optional(string)
    use_name_prefix = optional(bool, true)
    description     = optional(string)
    family          = string
    parameters      = optional(list(object({ name = string, value = string, apply_method = optional(string, "immediate") })), [])
    tags            = optional(map(string), {})
  })
  default = null

  validation {
    condition     = var.cluster_parameter_group == null ? true : alltrue([for parameter in var.cluster_parameter_group.parameters : contains(["immediate", "pending-reboot"], parameter.apply_method)])
    error_message = "Parameter apply_method must be immediate or pending-reboot."
  }
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Instance cluster logs to export. Enable corresponding audit/profiler parameters as well."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for log in var.enabled_cloudwatch_logs_exports : contains(["audit", "profiler"], log)])
    error_message = "Supported log exports are audit and profiler."
  }
}

variable "create_cloudwatch_log_groups" {
  description = "Create log groups before enabling exports."
  type        = bool
  default     = true
  nullable    = false
}

variable "cloudwatch_log_group_deletion_protection" {
  description = "Protect managed log groups from deletion."
  type        = bool
  default     = true
  nullable    = false
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Retain log groups when removing them from Terraform management."
  type        = bool
  default     = false
  nullable    = false
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Retention for managed CloudWatch log groups."
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "Use a CloudWatch-supported retention period."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "Existing KMS key ARN for log encryption."
  type        = string
  default     = null
}

variable "cloudwatch_log_group_class" {
  description = "Class for exported service logs. DocumentDB service delivery uses STANDARD."
  type        = string
  default     = "STANDARD"
  nullable    = false

  validation {
    condition     = var.cloudwatch_log_group_class == "STANDARD"
    error_message = "DocumentDB log export requires STANDARD log groups."
  }
}

variable "elastic_cluster" {
  description = "Required Elastic cluster settings when cluster_type is elastic. Provider auth_type supports PLAIN_TEXT or SECRET_ARN; service availability must be confirmed."
  type = object({
    admin_user_name      = optional(string, "dbadmin")
    auth_type            = optional(string, "PLAIN_TEXT")
    shard_capacity       = number
    shard_count          = number
    shard_instance_count = optional(number, 2)
  })
  default = null

  validation {
    condition     = var.elastic_cluster == null ? true : (contains(["PLAIN_TEXT", "SECRET_ARN"], var.elastic_cluster.auth_type) && contains([2, 4, 8, 16, 32, 64], var.elastic_cluster.shard_capacity) && var.elastic_cluster.shard_count >= 1 && var.elastic_cluster.shard_count <= 32 && floor(var.elastic_cluster.shard_count) == var.elastic_cluster.shard_count && (var.elastic_cluster.shard_instance_count >= 1 && var.elastic_cluster.shard_instance_count <= 16 && floor(var.elastic_cluster.shard_instance_count) == var.elastic_cluster.shard_instance_count))
    error_message = "Elastic requires a valid auth_type, shard capacity of 2/4/8/16/32/64, 1-32 whole shards, and 1-16 whole instances per shard."
  }
}

variable "elastic_admin_user_password" {
  description = "Elastic administrator password or secret ARN according to auth_type. The provider persists this sensitive value in state and has no write-only alternative."
  type        = string
  default     = null
  sensitive   = true
}

variable "event_subscriptions" {
  description = "Subscriptions to existing SNS topics. Set use_cluster_source to target this instance cluster; otherwise pass source_type/source_ids or omit both for all sources."
  type = map(object({
    name               = optional(string)
    name_prefix        = optional(string)
    sns_topic_arn      = string
    enabled            = optional(bool, true)
    event_categories   = optional(set(string))
    source_type        = optional(string)
    source_ids         = optional(set(string))
    use_cluster_source = optional(bool, false)
    tags               = optional(map(string), {})
    timeouts           = optional(object({ create = optional(string), update = optional(string), delete = optional(string) }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for subscription in var.event_subscriptions : !(subscription.name != null && subscription.name_prefix != null) && (subscription.source_type == null ? true : contains(["db-instance", "db-cluster", "db-parameter-group", "db-security-group", "db-cluster-snapshot"], subscription.source_type)) && (subscription.source_ids == null || subscription.source_type != null) && (!subscription.use_cluster_source || (subscription.source_ids == null && subscription.source_type == null))])
    error_message = "Subscription names/prefixes conflict; source_ids requires source_type; use_cluster_source replaces both source fields."
  }
}

variable "snapshots" {
  description = "One-time snapshots keyed by stable names. Omit db_cluster_identifier to snapshot this module cluster after its instances are ready."
  type = map(object({
    db_cluster_snapshot_identifier = string
    db_cluster_identifier          = optional(string)
    create_timeout                 = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "cluster_timeouts" {
  description = "Optional create/update/delete operation timeouts; null uses provider defaults."
  type        = object({ create = optional(string), update = optional(string), delete = optional(string) })
  default     = null
}

variable "instance_timeouts" {
  description = "Optional create/update/delete operation timeouts; null uses provider defaults."
  type        = object({ create = optional(string), update = optional(string), delete = optional(string) })
  default     = null
}

variable "global_cluster_timeouts" {
  description = "Optional create/update/delete operation timeouts; null uses provider defaults."
  type        = object({ create = optional(string), update = optional(string), delete = optional(string) })
  default     = null
}

variable "elastic_cluster_timeouts" {
  description = "Optional create/update/delete operation timeouts; null uses provider defaults."
  type        = object({ create = optional(string), update = optional(string), delete = optional(string) })
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources supporting tags, plus DocumentDB module identity tags."
  type        = map(string)
  default     = {}
  nullable    = false
}
