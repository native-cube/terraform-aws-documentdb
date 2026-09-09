# Global DocumentDB example

Creates a primary and a read-only secondary in separate Regions using provider aliases. The secondary waits for primary instances, inherits credentials, and uses its own regional KMS key and networking. Set a common supported engine version and instance class for both Regions.

Provide the primary password through the ephemeral `master_password_wo` variable and increment `master_password_wo_version` on rotation. AWS-managed passwords are unsupported for global databases.

Set the required variables, then run `terraform init` and `terraform plan`. Both regional clusters and the global container use deletion protection. Failover is an operational AWS procedure; after failover, reconcile primary/secondary configuration and review the plan before applying.
