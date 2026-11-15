# 02 – AWS account readiness

## Goal
Make the AWS account safe and ready before building anything.

## What I did
| Check | Found | Action |
|---|---|---|
| Tools | AWS CLI 2.34, Terraform 1.15.4 | None needed |
| Identity | IAM user `terraform-user`, not root | None needed |
| Region | CLI default was `us-east-1` | Changed to `ca-central-1` |
| Permissions | User had ECR and CloudFront; group `terraform-course` added EC2, RDS, IAM, S3, DynamoDB. DMS, Secrets Manager and Budgets were missing | Attached `AdministratorAccess` (personal lab account) |
| Budgets | None | Created $10 and $20 budgets with Terraform (`infra/bootstrap`) |

## What I learned
- Permissions come from three places: policies on the user, groups, and inline policies. I had to check all three.
- `IAMFullAccess` is effectively admin, because it can grant itself anything. In a company I would use least privilege instead.
- My first Terraform: `init`, `validate`, `plan` (2 to add), `apply`. I watched the budgets appear in the console.
- The bootstrap folder stays deployed. Budgets are free and are the safety net for the rest of the project.

## Cost
$0
