# Terraform AWS DocumentDB Module

Supports provisioned and Serverless instance clusters, mixed instance classes, global databases, Elastic clusters, snapshot and point-in-time restores, one-time snapshots, event subscriptions, parameter groups, subnet groups, security groups, and CloudWatch log groups.

The root module accepts existing VPCs, subnets, KMS keys, and SNS topics. Configure AWS providers in the calling configuration. Defaults include encrypted storage, seven-day backups, deletion protection and a required final snapshot for instance-based clusters, managed credentials for new standalone primaries, and no security group traffic rules until declared. The default compute configuration is one instance; add readers for compute redundancy.

## Usage

```hcl
module "documentdb" {
  source = "./terraform-aws-documentdb"

  name                      = "orders-production"
  engine_version            = var.documentdb_engine_version
  instance_class            = var.documentdb_instance_class
  vpc_id                    = var.vpc_id
  subnet_ids                = var.private_subnet_ids
  final_snapshot_identifier = "orders-production-final-v1"

  instances = {
    writer = {}
    reader = { promotion_tier = 1 }
  }

  ingress_rules = {
    application = {
      description                  = "Application database access"
      referenced_security_group_id = var.application_security_group_id
    }
  }

  tags = {
    Environment = "production"
    Service     = "orders"
  }
}
```

Use the local source path until the repository is published. No release or Registry version has been published by this implementation.

## Deployment modes

| Mode | Configuration |
| --- | --- |
| Provisioned | `cluster_type = "instance"` (default), with instances keyed by stable names |
| Serverless | Set `serverless_v2_scaling_configuration` and use `db.serverless` instances |
| Mixed compute | Override `instance_class` on individual entries to mix provisioned and Serverless instances |
| Global primary | `create_global_cluster = true`, with caller-managed credentials |
| Global secondary | Existing `global_cluster_identifier`, `is_primary_cluster = false`, and the secondary Region's provider or `region` |
| Global container only | `create_cluster = false` and `create_global_cluster = true`; optionally supply an existing external primary ARN |
| Elastic | `cluster_type = "elastic"`, `elastic_cluster`, and `elastic_admin_user_password` |
| Disabled | `create = false` creates no resources or data lookups |

`instances = {}` permits a cluster whose compute is managed externally. Map keys determine Terraform addresses; an entry called `writer` does not permanently assign the writer role, which AWS may change during failover. Promotion tiers control failover priority.

## Provider coverage

Every documented configurable argument and nested configuration block for these eight resources is exposed directly, through a typed object, or through a module-managed relationship. Engine versions and instance classes are not restricted to a hard-coded release list. Read-only attributes, generated `id`, and provider-derived `tags_all` are not input arguments.

| Resource | Module configuration |
| --- | --- |
| `aws_docdb_cluster` | Cluster inputs, three password modes, restore/scaling blocks, `cluster_timeouts`, and managed network/parameter/global relationships |
| `aws_docdb_cluster_instance` | `instances` overrides and shared instance defaults; includes CA rotation, Performance Insights, identifier prefixes, maintenance and timeouts |
| `aws_docdb_global_cluster` | `create_global_cluster`, `global_cluster_*`, shared engine/encryption settings and timeouts |
| `aws_docdbelastic_cluster` | `elastic_cluster`, sensitive password input, shared backups/networking/encryption/tags, and Elastic timeouts |
| `aws_docdb_subnet_group` | Create/reuse subnet group, name/prefix, description, subnet IDs, Region and tags |
| `aws_docdb_cluster_parameter_group` | `cluster_parameter_group`, including name/prefix, family, description, parameters and tags |
| `aws_docdb_event_subscription` | `event_subscriptions`, including explicit or all-source subscriptions, SNS target, categories, names/prefixes, tags and timeouts |
| `aws_docdb_cluster_snapshot` | `snapshots`, including an optional external source, snapshot name and create timeout |

The provider exposes `cluster_members` as an optional computed set, but does not use it to create instances. Leave it null and manage membership with `instances`. Global containers and DocumentDB cluster snapshots do not expose tags in this provider version.

The resource set includes those in the [dare-global reference module](https://registry.terraform.io/modules/dare-global/documentdb/aws/latest), plus global databases, Elastic clusters, snapshots, and event subscriptions. Implementation was verified against the [AWS provider 6.63.0 source](https://github.com/hashicorp/terraform-provider-aws/tree/v6.63.0/internal/service/docdb) and its [Elastic resource](https://github.com/hashicorp/terraform-provider-aws/blob/v6.63.0/internal/service/docdbelastic/cluster.go).

## Credentials

New standalone primaries use DocumentDB-managed passwords by default. `master_user_secret_arn` and `master_user_secret` expose secret metadata, never its password. This provider has no DocumentDB input for selecting the managed secret's KMS key; `kms_key_id` controls database storage encryption.

For caller-managed credentials, set `manage_master_user_password = false`, pass the ephemeral `master_password_wo`, and supply a positive `master_password_wo_version`. Increment the version whenever the password changes. Terraform 1.11+ sends the write-only value without persisting it in plan or state. The optional legacy `master_password` argument is sensitive but is stored in state; prefer the write-only alternative. These password modes conflict.

Global databases require caller-managed credentials on the primary; the module omits credentials on secondaries. This follows [AWS's managed-password restrictions](https://docs.aws.amazon.com/documentdb/latest/devguide/docdb-secrets-manager.html).

Elastic uses a separate `elastic_admin_user_password`. Its provider resource has no write-only argument, so Terraform stores that sensitive value in state. The provider exposes both `PLAIN_TEXT` and `SECRET_ARN` authentication enums; the runnable example uses `PLAIN_TEXT`. AWS currently lists Secrets Manager among [Elastic limitations](https://docs.aws.amazon.com/documentdb/latest/devguide/docdb-using-elastic-clusters.html), so do not assume the API enum means the service supports that workflow in your deployment.

## Networking, logging, and upgrades

Supply private subnets in at least two Availability Zones. Live network checks validate the provided subnets, existing security groups, and reused subnet group's VPC/network type. Explicit `availability_zones` must contain three distinct AZs because AWS otherwise adds storage AZs, causing persistent Terraform differences. Null leaves storage AZ selection to AWS. `network_type = "DUAL"` requires IPv6-capable subnets.

Each security rule requires exactly one IPv4 CIDR, IPv6 CIDR, prefix list, or referenced security group. TCP/UDP ports default to the database port. Other protocols use the supplied ports/type/code; protocol `-1` must omit ports. `create_security_group = false` requires existing security group IDs and means rule maps are not used. Use generated names for managed security/parameter groups to permit create-before-destroy replacement; fixed names may require an explicit rename when replacing a resource.

`validate_engine_capabilities` queries the selected Region for the requested engine version, instance class, Availability Zone, log exports and parameter family. Keep both validation switches enabled for normal plans. Mocked/offline consumers can disable them. Regional service combinations, quotas, Serverless availability, and global database eligibility remain AWS validations; a successful mocked plan does not prove deployability in an account.

Configure engine parameters to enable auditing/profiling and select the corresponding `enabled_cloudwatch_logs_exports`. Log groups are created first with configurable retention, KMS encryption, deletion protection and skip-destroy behavior. See [AWS's two-step log export setup](https://docs.aws.amazon.com/documentdb/latest/devguide/event-auditing.html). Generated cluster identifier prefixes require `create_cloudwatch_log_groups = false`, since their eventual log group names are unknown before cluster creation. Other resources continue to use `name` as their naming base.

Set `engine_version` explicitly for controlled upgrades; null permits the AWS default. Instance minor upgrades and certificate settings are configurable. `apply_immediately = false` defers eligible changes to maintenance. `storage_type = "iopt1"` selects I/O-Optimized storage. Serverless DCUs support half-unit increments with minimum capacity at least 0.5 and maximum capacity from 1 to 256; removing the scaling block forces replacement.

## Restore, global lifecycle, and snapshots

Choose one of `snapshot_identifier` or `restore_to_point_in_time`. PITR requires exactly one of an RFC3339 `restore_to_time` or `use_latest_restorable_time = true`. Restores inherit credentials, so the module omits all primary credential settings. To change credential ownership after restoration, complete and review that as a separate operational change; simply supplying a password while the restore input remains configured does not rotate it through this module.

The provider's PITR creation path does not forward every ordinary cluster setting. Review a subsequent plan after restoration to reconcile settings such as backup retention, maintenance windows and parameter-group association. Storage encryption is inherited from the source; setting `storage_encrypted = true` is not a conversion mechanism for an unencrypted snapshot. The restore APIs do not attach global membership, so the module rejects a restore combined with a global identifier.

To create a global database from an existing primary, use a separate module call with `create_cluster = false` and `global_cluster_source_db_cluster_identifier` set to that external cluster ARN. The new container inherits engine, database name and encryption. The source cluster's owning configuration must account for the resulting global membership. Do not reference a cluster created by the same container call. Global major version upgrades and failovers have service-specific procedures; after a failover, reconcile role settings before applying Terraform. See the [provider's global database documentation](https://registry.terraform.io/providers/hashicorp/aws/6.63.0/docs/resources/docdb_global_cluster).

`snapshots` creates one-time snapshots after module-managed instances exist; it is not a recurring schedule. Use stable map keys and unique snapshot names. Omit a snapshot's cluster identifier to target this module's instance cluster, or supply an external instance-cluster identifier. Event subscriptions accept an existing SNS topic; `use_cluster_source = true` selects this module's instance cluster. Without that setting or explicit source filters, the subscription receives events for all sources supported by the selected categories.

Instance clusters require a unique `final_snapshot_identifier` unless final snapshots are explicitly skipped. Before deletion, disable applicable cluster/global/log-group deletion protection and review the resulting plan. Change final snapshot names before deleting a recreated cluster to avoid collisions.

Elastic's separate API does not expose instance-cluster deletion protection, final-snapshot-on-delete, PITR, parameter groups, instance-level Performance Insights or DocumentDB global membership. Shared instance-only defaults such as `deletion_protection`, `skip_final_snapshot`, `manage_master_user_password`, `instances`, and instance tuning do not configure Elastic. Backups, maintenance, shard capacity/count, 1-16 instances per shard, networking and KMS settings do. The root module rejects explicit unsupported restore, global, Serverless, parameter and log-export combinations. See [Elastic setup and shard limits](https://docs.aws.amazon.com/documentdb/latest/devguide/elastic-get-started.html).

## Examples

- [Basic](examples/basic): provisioned standalone cluster with managed credentials.
- [Complete](examples/complete): writer/reader, I/O-Optimized storage, encryption, logging, parameters, events and a snapshot.
- [Serverless](examples/serverless): Serverless writer and reader.
- [Global cluster](examples/global-cluster): primary and secondary with regional providers and ephemeral primary credentials.
- [Elastic](examples/elastic): sharded deployment using the separate Elastic API.
- [Restore](examples/restore): snapshot or point-in-time recovery.

Examples consume `../..` and take existing infrastructure as required inputs. Engine versions remain caller-selected so examples do not silently choose an upgrade or assume regional availability.

## Development

Run `make check` for formatting, generated docs, initialization, validation, native Terraform tests, and validation of every example. Tests use mocked providers and never contact AWS APIs. `make lint` runs TFLint; `make security` runs Trivy. `make hooks` enables the repository-local pre-commit hook after this directory is initialized as a Git repository.

GitHub Actions checks formatting, generated docs, TFLint and Trivy, then runs minimum and latest supported compatibility jobs. The minimum job explicitly pins AWS 6.63.0; the latest job upgrades within v6. Do not edit the generated documentation below manually; run `make docs` instead.

## Module documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.63.0, < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.63.0, < 7.0.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_docdb_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster) | resource |
| [aws_docdb_cluster_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster_instance) | resource |
| [aws_docdb_cluster_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster_parameter_group) | resource |
| [aws_docdb_cluster_snapshot.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_cluster_snapshot) | resource |
| [aws_docdb_event_subscription.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_event_subscription) | resource |
| [aws_docdb_global_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_global_cluster) | resource |
| [aws_docdb_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdb_subnet_group) | resource |
| [aws_docdbelastic_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/docdbelastic_cluster) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Allow an explicit major engine version upgrade. | `bool` | `false` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Apply modifications immediately instead of during the maintenance window. | `bool` | `false` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Default instance automatic minor version upgrade setting. | `bool` | `true` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Optional cluster storage Availability Zones. Supply exactly three to avoid perpetual AWS-added AZ drift. | `set(string)` | `null` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Days to retain automated backups (1-35). | `number` | `7` | no |
| <a name="input_ca_cert_identifier"></a> [ca\_cert\_identifier](#input\_ca\_cert\_identifier) | Default instance CA certificate identifier. | `string` | `null` | no |
| <a name="input_certificate_rotation_restart"></a> [certificate\_rotation\_restart](#input\_certificate\_rotation\_restart) | Default instance restart behavior for certificate rotation. | `bool` | `null` | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Class for exported service logs. DocumentDB service delivery uses STANDARD. | `string` | `"STANDARD"` | no |
| <a name="input_cloudwatch_log_group_deletion_protection"></a> [cloudwatch\_log\_group\_deletion\_protection](#input\_cloudwatch\_log\_group\_deletion\_protection) | Protect managed log groups from deletion. | `bool` | `true` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | Existing KMS key ARN for log encryption. | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Retention for managed CloudWatch log groups. | `number` | `30` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Retain log groups when removing them from Terraform management. | `bool` | `false` | no |
| <a name="input_cluster_identifier_prefix"></a> [cluster\_identifier\_prefix](#input\_cluster\_identifier\_prefix) | Optional generated cluster-name prefix instead of name. Related resource names still use name. | `string` | `null` | no |
| <a name="input_cluster_members"></a> [cluster\_members](#input\_cluster\_members) | Optional expected cluster member identifiers for provider drift detection. Membership is created through instances; normally leave null. | `set(string)` | `null` | no |
| <a name="input_cluster_parameter_group"></a> [cluster\_parameter\_group](#input\_cluster\_parameter\_group) | Optional cluster parameter group, including TLS, audit, profiler, and other engine parameters. | <pre>object({<br/>    name            = optional(string)<br/>    use_name_prefix = optional(bool, true)<br/>    description     = optional(string)<br/>    family          = string<br/>    parameters      = optional(list(object({ name = string, value = string, apply_method = optional(string, "immediate") })), [])<br/>    tags            = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_cluster_timeouts"></a> [cluster\_timeouts](#input\_cluster\_timeouts) | Optional create/update/delete operation timeouts; null uses provider defaults. | `object({ create = optional(string), update = optional(string), delete = optional(string) })` | `null` | no |
| <a name="input_cluster_type"></a> [cluster\_type](#input\_cluster\_type) | Deployment type: instance (provisioned or Serverless) or elastic. | `string` | `"instance"` | no |
| <a name="input_copy_tags_to_snapshot"></a> [copy\_tags\_to\_snapshot](#input\_copy\_tags\_to\_snapshot) | Copy instance tags to instance snapshots. | `bool` | `true` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create module-managed resources. | `bool` | `true` | no |
| <a name="input_create_cloudwatch_log_groups"></a> [create\_cloudwatch\_log\_groups](#input\_create\_cloudwatch\_log\_groups) | Create log groups before enabling exports. | `bool` | `true` | no |
| <a name="input_create_cluster"></a> [create\_cluster](#input\_create\_cluster) | Whether to create a regional cluster. Set false for a global container or standalone event/snapshot resources. | `bool` | `true` | no |
| <a name="input_create_db_subnet_group"></a> [create\_db\_subnet\_group](#input\_create\_db\_subnet\_group) | Create a subnet group for an instance cluster; false requires db\_subnet\_group\_name. | `bool` | `true` | no |
| <a name="input_create_global_cluster"></a> [create\_global\_cluster](#input\_create\_global\_cluster) | Create a DocumentDB global container. | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Create a security group with only explicitly declared rules. | `bool` | `true` | no |
| <a name="input_db_cluster_parameter_group_name"></a> [db\_cluster\_parameter\_group\_name](#input\_db\_cluster\_parameter\_group\_name) | Existing cluster parameter group; conflicts with cluster\_parameter\_group. | `string` | `null` | no |
| <a name="input_db_subnet_group_description"></a> [db\_subnet\_group\_description](#input\_db\_subnet\_group\_description) | Description of the managed subnet group. | `string` | `"DocumentDB subnet group"` | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | Name of an existing or module-created DocumentDB subnet group. | `string` | `null` | no |
| <a name="input_db_subnet_group_use_name_prefix"></a> [db\_subnet\_group\_use\_name\_prefix](#input\_db\_subnet\_group\_use\_name\_prefix) | Generate a unique subnet group name using db\_subnet\_group\_name or name as a prefix. | `bool` | `false` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Protect instance-based clusters from deletion. | `bool` | `true` | no |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | Explicit egress rules keyed by stable names. TCP/UDP ports default to the database port; exactly one traffic source/destination is required. | <pre>map(object({<br/>    description                  = optional(string)<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_elastic_admin_user_password"></a> [elastic\_admin\_user\_password](#input\_elastic\_admin\_user\_password) | Elastic administrator password or secret ARN according to auth\_type. The provider persists this sensitive value in state and has no write-only alternative. | `string` | `null` | no |
| <a name="input_elastic_cluster"></a> [elastic\_cluster](#input\_elastic\_cluster) | Required Elastic cluster settings when cluster\_type is elastic. Provider auth\_type supports PLAIN\_TEXT or SECRET\_ARN; service availability must be confirmed. | <pre>object({<br/>    admin_user_name      = optional(string, "dbadmin")<br/>    auth_type            = optional(string, "PLAIN_TEXT")<br/>    shard_capacity       = number<br/>    shard_count          = number<br/>    shard_instance_count = optional(number, 2)<br/>  })</pre> | `null` | no |
| <a name="input_elastic_cluster_timeouts"></a> [elastic\_cluster\_timeouts](#input\_elastic\_cluster\_timeouts) | Optional create/update/delete operation timeouts; null uses provider defaults. | `object({ create = optional(string), update = optional(string), delete = optional(string) })` | `null` | no |
| <a name="input_enable_performance_insights"></a> [enable\_performance\_insights](#input\_enable\_performance\_insights) | Enable Performance Insights on instances by default. | `bool` | `false` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | Instance cluster logs to export. Enable corresponding audit/profiler parameters as well. | `set(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | DocumentDB database engine. | `string` | `"docdb"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Engine version for instance-based and new global clusters. Null uses the AWS default; pin explicitly for controlled upgrades. | `string` | `null` | no |
| <a name="input_event_subscriptions"></a> [event\_subscriptions](#input\_event\_subscriptions) | Subscriptions to existing SNS topics. Set use\_cluster\_source to target this instance cluster; otherwise pass source\_type/source\_ids or omit both for all sources. | <pre>map(object({<br/>    name               = optional(string)<br/>    name_prefix        = optional(string)<br/>    sns_topic_arn      = string<br/>    enabled            = optional(bool, true)<br/>    event_categories   = optional(set(string))<br/>    source_type        = optional(string)<br/>    source_ids         = optional(set(string))<br/>    use_cluster_source = optional(bool, false)<br/>    tags               = optional(map(string), {})<br/>    timeouts           = optional(object({ create = optional(string), update = optional(string), delete = optional(string) }))<br/>  }))</pre> | `{}` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | Unique final snapshot name required unless skip\_final\_snapshot is true. Change before deleting a recreated cluster. | `string` | `null` | no |
| <a name="input_global_cluster_database_name"></a> [global\_cluster\_database\_name](#input\_global\_cluster\_database\_name) | Optional provider database\_name argument for a new empty global container; not used when inheriting from a source. | `string` | `null` | no |
| <a name="input_global_cluster_deletion_protection"></a> [global\_cluster\_deletion\_protection](#input\_global\_cluster\_deletion\_protection) | Protect the global container from deletion. | `bool` | `true` | no |
| <a name="input_global_cluster_identifier"></a> [global\_cluster\_identifier](#input\_global\_cluster\_identifier) | Existing global container to join, or new container name (defaults to <name>-global). | `string` | `null` | no |
| <a name="input_global_cluster_source_db_cluster_identifier"></a> [global\_cluster\_source\_db\_cluster\_identifier](#input\_global\_cluster\_source\_db\_cluster\_identifier) | Existing external primary cluster ARN for creating a global container. Requires create\_cluster = false to avoid circular dependencies. | `string` | `null` | no |
| <a name="input_global_cluster_timeouts"></a> [global\_cluster\_timeouts](#input\_global\_cluster\_timeouts) | Optional create/update/delete operation timeouts; null uses provider defaults. | `object({ create = optional(string), update = optional(string), delete = optional(string) })` | `null` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | Explicit ingress rules keyed by stable names. TCP/UDP ports default to the database port; exactly one traffic source/destination is required. | <pre>map(object({<br/>    description                  = optional(string)<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | Default instance class; any regionally supported class is accepted, including db.serverless. | `string` | `"db.r6g.large"` | no |
| <a name="input_instance_timeouts"></a> [instance\_timeouts](#input\_instance\_timeouts) | Optional create/update/delete operation timeouts; null uses provider defaults. | `object({ create = optional(string), update = optional(string), delete = optional(string) })` | `null` | no |
| <a name="input_instances"></a> [instances](#input\_instances) | Instance configurations keyed by stable caller-chosen keys. Empty maps permit externally managed compute; used only for instance clusters. | <pre>map(object({<br/>    identifier                      = optional(string)<br/>    identifier_prefix               = optional(string)<br/>    instance_class                  = optional(string)<br/>    availability_zone               = optional(string)<br/>    apply_immediately               = optional(bool)<br/>    auto_minor_version_upgrade      = optional(bool)<br/>    ca_cert_identifier              = optional(string)<br/>    certificate_rotation_restart    = optional(bool)<br/>    copy_tags_to_snapshot           = optional(bool)<br/>    enable_performance_insights     = optional(bool)<br/>    performance_insights_kms_key_id = optional(string)<br/>    preferred_maintenance_window    = optional(string)<br/>    promotion_tier                  = optional(number, 0)<br/>    tags                            = optional(map(string), {})<br/>    timeouts                        = optional(object({ create = optional(string), update = optional(string), delete = optional(string) }))<br/>  }))</pre> | <pre>{<br/>  "one": {}<br/>}</pre> | no |
| <a name="input_is_primary_cluster"></a> [is\_primary\_cluster](#input\_is\_primary\_cluster) | Whether this is the primary cluster; false requires a global cluster identifier and omits credentials. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Existing KMS key ARN for cluster storage encryption; null uses the AWS-managed key. | `string` | `null` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Let DocumentDB manage the password in Secrets Manager. Set false for global databases or caller-managed passwords. Restore operations inherit credentials. | `bool` | `true` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Optional legacy caller-managed password stored in Terraform state. Prefer master\_password\_wo. Conflicts with managed passwords and write-only credentials. | `string` | `null` | no |
| <a name="input_master_password_wo"></a> [master\_password\_wo](#input\_master\_password\_wo) | Ephemeral write-only password; never stored in plans or state. Supply a version to trigger rotation. | `string` | `null` | no |
| <a name="input_master_password_wo_version"></a> [master\_password\_wo\_version](#input\_master\_password\_wo\_version) | Positive password rotation version. Increment whenever master\_password\_wo changes. | `number` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Primary cluster administrator username. Omitted for restores and global secondaries. | `string` | `"dbadmin"` | no |
| <a name="input_name"></a> [name](#input\_name) | Cluster name and default prefix for related resources. | `string` | n/a | yes |
| <a name="input_network_type"></a> [network\_type](#input\_network\_type) | Instance cluster network stack. DUAL requires IPv6-capable subnets. | `string` | `"IPV4"` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | Default existing KMS key for instance Performance Insights; requires enable\_performance\_insights. | `string` | `null` | no |
| <a name="input_port"></a> [port](#input\_port) | Database port; Elastic supports only 27017. | `number` | `27017` | no |
| <a name="input_preferred_backup_window"></a> [preferred\_backup\_window](#input\_preferred\_backup\_window) | Daily UTC backup window (hh:mm-hh:mm); null lets AWS select. | `string` | `null` | no |
| <a name="input_preferred_maintenance_window"></a> [preferred\_maintenance\_window](#input\_preferred\_maintenance\_window) | Weekly UTC cluster maintenance window (ddd:hh:mm-ddd:hh:mm). | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Optional resource Region; defaults to the AWS provider Region. | `string` | `null` | no |
| <a name="input_restore_to_point_in_time"></a> [restore\_to\_point\_in\_time](#input\_restore\_to\_point\_in\_time) | Point-in-time restore source and exactly one time selection. Credentials are inherited. | <pre>object({<br/>    source_cluster_identifier  = string<br/>    restore_type               = optional(string, "full-copy")<br/>    restore_to_time            = optional(string)<br/>    use_latest_restorable_time = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_revoke_rules_on_delete"></a> [revoke\_rules\_on\_delete](#input\_revoke\_rules\_on\_delete) | Revoke security group rules before deleting the group. | `bool` | `false` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description of the managed security group. | `string` | `"DocumentDB access"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Existing VPC security groups to attach alongside the optional managed group. | `list(string)` | `[]` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Optional name of the module-created security group. | `string` | `null` | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | Generate a unique security group name from its configured name. | `bool` | `true` | no |
| <a name="input_serverless_v2_scaling_configuration"></a> [serverless\_v2\_scaling\_configuration](#input\_serverless\_v2\_scaling\_configuration) | Serverless DCU range. Use db.serverless instances. Removing this block replaces the cluster. | `object({ min_capacity = number, max_capacity = number })` | `null` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Skip the final instance-cluster snapshot at deletion. | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Existing snapshot identifier or ARN to restore; conflicts with point-in-time restore. | `string` | `null` | no |
| <a name="input_snapshots"></a> [snapshots](#input\_snapshots) | One-time snapshots keyed by stable names. Omit db\_cluster\_identifier to snapshot this module cluster after its instances are ready. | <pre>map(object({<br/>    db_cluster_snapshot_identifier = string<br/>    db_cluster_identifier          = optional(string)<br/>    create_timeout                 = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Whether instance cluster storage is encrypted. Elastic always encrypts storage. | `bool` | `true` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | Instance cluster storage configuration: standard or I/O-Optimized (iopt1). | `string` | `"standard"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Existing private subnet IDs spanning at least two Availability Zones. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources supporting tags, plus DocumentDB module identity tags. | `map(string)` | `{}` | no |
| <a name="input_validate_engine_capabilities"></a> [validate\_engine\_capabilities](#input\_validate\_engine\_capabilities) | Query regional engine versions and instance offerings during planning. | `bool` | `true` | no |
| <a name="input_validate_network_configuration"></a> [validate\_network\_configuration](#input\_validate\_network\_configuration) | Read subnet/security-group metadata to check VPC, AZ, and IPv6 compatibility. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Existing VPC ID. Required when creating a security group; also used by network validation. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudwatch_log_group_arns"></a> [cloudwatch\_log\_group\_arns](#output\_cloudwatch\_log\_group\_arns) | Log group ARNs keyed by export type. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | Cluster ARN. |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Writer DNS endpoint. |
| <a name="output_cluster_engine_version"></a> [cluster\_engine\_version](#output\_cluster\_engine\_version) | Actual engine version. |
| <a name="output_cluster_hosted_zone_id"></a> [cluster\_hosted\_zone\_id](#output\_cluster\_hosted\_zone\_id) | Endpoint Route 53 hosted zone ID. |
| <a name="output_cluster_identifier"></a> [cluster\_identifier](#output\_cluster\_identifier) | Cluster identifier. |
| <a name="output_cluster_members"></a> [cluster\_members](#output\_cluster\_members) | Cluster instance identifiers. |
| <a name="output_cluster_parameter_group_arn"></a> [cluster\_parameter\_group\_arn](#output\_cluster\_parameter\_group\_arn) | Module-created parameter group ARN. |
| <a name="output_cluster_parameter_group_name"></a> [cluster\_parameter\_group\_name](#output\_cluster\_parameter\_group\_name) | Managed or supplied cluster parameter group name. |
| <a name="output_cluster_port"></a> [cluster\_port](#output\_cluster\_port) | Database port. |
| <a name="output_cluster_reader_endpoint"></a> [cluster\_reader\_endpoint](#output\_cluster\_reader\_endpoint) | Reader DNS endpoint. |
| <a name="output_cluster_resource_id"></a> [cluster\_resource\_id](#output\_cluster\_resource\_id) | Immutable regional cluster resource ID. |
| <a name="output_db_subnet_group_arn"></a> [db\_subnet\_group\_arn](#output\_db\_subnet\_group\_arn) | Module-created subnet group ARN. |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | Managed or supplied subnet group name. |
| <a name="output_elastic_cluster_arn"></a> [elastic\_cluster\_arn](#output\_elastic\_cluster\_arn) | Elastic cluster arn. |
| <a name="output_elastic_cluster_endpoint"></a> [elastic\_cluster\_endpoint](#output\_elastic\_cluster\_endpoint) | Elastic cluster endpoint. |
| <a name="output_elastic_cluster_id"></a> [elastic\_cluster\_id](#output\_elastic\_cluster\_id) | Elastic cluster id. |
| <a name="output_event_subscription_arns"></a> [event\_subscription\_arns](#output\_event\_subscription\_arns) | Event subscription ARNs keyed by caller names. |
| <a name="output_global_cluster_arn"></a> [global\_cluster\_arn](#output\_global\_cluster\_arn) | DocumentDB global container arn. |
| <a name="output_global_cluster_id"></a> [global\_cluster\_id](#output\_global\_cluster\_id) | DocumentDB global container global cluster identifier. |
| <a name="output_global_cluster_members"></a> [global\_cluster\_members](#output\_global\_cluster\_members) | DocumentDB global container global cluster members. |
| <a name="output_global_cluster_resource_id"></a> [global\_cluster\_resource\_id](#output\_global\_cluster\_resource\_id) | DocumentDB global container global cluster resource id. |
| <a name="output_global_cluster_status"></a> [global\_cluster\_status](#output\_global\_cluster\_status) | DocumentDB global container status. |
| <a name="output_instances"></a> [instances](#output\_instances) | Instance metadata keyed by the caller-provided instance keys. |
| <a name="output_master_user_secret"></a> [master\_user\_secret](#output\_master\_user\_secret) | Managed secret metadata only: ARN, KMS key, and status. No password is returned. |
| <a name="output_master_user_secret_arn"></a> [master\_user\_secret\_arn](#output\_master\_user\_secret\_arn) | ARN of the DocumentDB-managed password secret, when available. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Module-created security group ID. |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Security group IDs attached to the cluster. |
| <a name="output_snapshot_arns"></a> [snapshot\_arns](#output\_snapshot\_arns) | Snapshot ARNs keyed by caller names. |
<!-- END_TF_DOCS -->
