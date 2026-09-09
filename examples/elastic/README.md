# Elastic DocumentDB example

An Elastic cluster with two shards and two instances per shard. Elastic has a separate AWS API: instance-based deletion protection, final snapshots, parameter groups, logging, Performance Insights, global membership, and Serverless settings do not apply. The provider persists the sensitive administrator password in Terraform state. Protect the backend accordingly.

Requires existing networking and an AWS identity with permission to manage these resources. Set all required inputs in an untracked `terraform.tfvars` or through `TF_VAR_*`.

```sh
terraform init
terraform plan
```

Review the plan and regional engine/instance availability before applying. Root-module defaults keep instance-cluster storage encrypted, backups retained for seven days, and deletion protection enabled.
