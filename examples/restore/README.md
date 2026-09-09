# Restore DocumentDB example

This example uses the local module source `../..`. To use the published [native-cube/documentdb/aws module](https://registry.terraform.io/modules/native-cube/documentdb/aws/latest), set each module block to `source = "native-cube/documentdb/aws"` and add `version = "~> 1.0"`. See the [module usage instructions](../../README.md#usage).

Restore from a snapshot or point in time. For a snapshot, set `snapshot_identifier`. For PITR, set `restore_to_point_in_time = { source_cluster_identifier = "source-cluster", use_latest_restorable_time = true }`. Validation requires exactly one restore source and rejects empty snapshot names. The cluster inherits its source credentials by default; see the [root README](../../README.md#restore-global-lifecycle-and-snapshots) for provider limitations and the follow-up plan after PITR.

After restoration completes, keep the restore input and set `manage_credentials_after_restore = true` on a subsequent apply. Leave `manage_master_user_password = true` to let DocumentDB manage the password. For caller-managed credentials, set it to `false`, provide the ephemeral `master_password_wo`, and set `master_password_wo_version` to a positive integer. Increment that version with each later password change. The inherited administrator username remains unchanged. Leave credential management disabled during initial restoration, especially PITR, whose provider creation path does not apply password settings.

Requires existing networking and an AWS identity with permission to manage these resources. Set all required inputs in an untracked `terraform.tfvars` or through `TF_VAR_*`.

```sh
terraform init
terraform plan
```

Review the plan and regional engine/instance availability before applying. Root-module defaults keep instance-cluster storage encrypted, backups retained for seven days, and deletion protection enabled.
