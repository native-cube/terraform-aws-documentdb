# DocumentDB Module Instructions

These instructions apply to this repository.

- Maintain a reusable DocumentDB module, accepting existing networking, encryption keys, and SNS topics. Configure AWS providers only in examples or callers.
- Keep root Terraform files split by concern. Document all variables and outputs, use typed objects and stable `for_each` keys, and preserve v1 interfaces/resource addresses after release.
- Verify new arguments against the released AWS provider schema and official AWS documentation. Keep instance-based, Serverless, global, and Elastic capabilities distinct.
- Preserve encrypted storage, backups, explicit network access and instance/global deletion protection defaults. Prefer managed or ephemeral write-only credentials; never output password values.
- Keep examples under `examples/` using `../..`. Document state implications for legacy and Elastic password inputs.
- Run `terraform fmt -recursive` and `make docs` after editing Terraform. Never hand-edit between terraform-docs markers.
- Run `make check` before completing a change; CI additionally runs TFLint, Trivy and minimum/latest compatibility tests. Native tests must use mocked providers and cover meaningful deployment behavior and invalid combinations.
- Do not commit `.terraform/`, state, plans, credentials or real tfvars. Never apply or destroy infrastructure unless explicitly requested for a confirmed environment.
