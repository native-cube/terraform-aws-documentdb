# Serverless DocumentDB example

A Serverless writer and reader sharing a 0.5-16 DCU capacity range. Provisioned readers can be mixed in by overriding instance_class on individual map entries. Removing the scaling configuration forces cluster replacement.

Requires existing networking and an AWS identity with permission to manage these resources. Set all required inputs in an untracked `terraform.tfvars` or through `TF_VAR_*`.

```sh
terraform init
terraform plan
```

Review the plan and regional engine/instance availability before applying. Root-module defaults keep instance-cluster storage encrypted, backups retained for seven days, and deletion protection enabled.
