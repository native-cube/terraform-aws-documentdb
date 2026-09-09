# Complete DocumentDB example

This example uses the local module source `../..`. To use the published [native-cube/documentdb/aws module](https://registry.terraform.io/modules/native-cube/documentdb/aws/latest), set each module block to `source = "native-cube/documentdb/aws"` and add `version = "~> 1.0"`. See the [module usage instructions](../../README.md#usage).

A writer and reader with I/O-Optimized storage, custom encryption, TLS parameters, audit/profiler logs, Performance Insights, event delivery, and a one-time snapshot. To enable dual-stack, set `network_type = "DUAL"` and use IPv6-capable private subnets.

Requires existing networking and an AWS identity with permission to manage these resources. Set all required inputs in an untracked `terraform.tfvars` or through `TF_VAR_*`.

```sh
terraform init
terraform plan
```

Review the plan and regional engine/instance availability before applying. Root-module defaults keep instance-cluster storage encrypted, backups retained for seven days, and deletion protection enabled.
