# Basic DocumentDB example

A provisioned instance cluster with managed credentials and explicit application access. Add readers through the `instances` map for compute redundancy.

Requires existing networking and an AWS identity with permission to manage these resources. Set all required inputs in an untracked `terraform.tfvars` or through `TF_VAR_*`.

```sh
terraform init
terraform plan
```

Review the plan and regional engine/instance availability before applying. Root-module defaults keep instance-cluster storage encrypted, backups retained for seven days, and deletion protection enabled.
