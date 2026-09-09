# Restore DocumentDB example

Restore from a snapshot or point in time. For a snapshot, set `snapshot_identifier`. For PITR, set `restore_to_point_in_time = { source_cluster_identifier = "source-cluster", use_latest_restorable_time = true }`. Supply exactly one restore mode. The cluster inherits its source credentials; see the root README for provider limitations and the follow-up plan after PITR.

Requires existing networking and an AWS identity with permission to manage these resources. Set all required inputs in an untracked `terraform.tfvars` or through `TF_VAR_*`.

```sh
terraform init
terraform plan
```

Review the plan and regional engine/instance availability before applying. Root-module defaults keep instance-cluster storage encrypted, backups retained for seven days, and deletion protection enabled.
