# 06 – Target database (RDS MySQL)

## Goal
Create the managed database the app will move to, with no hardcoded password.

## What I built (Terraform, `infra/target/database.tf`)
| Resource | Setting | Why |
|---|---|---|
| DB subnet group | `db-a` + `db-b` | RDS may only use the private database subnets, across two zones |
| Security group | 3306 from `10.1.11.0/24` and `10.1.12.0/24` only, no outbound rules | Only the app tier can reach the database |
| RDS MySQL 8.4, `db.t4g.micro` | Encrypted, not publicly accessible, single-AZ for now | Managed database; Multi-AZ switched on later for failover testing |
| Master password | `manage_master_user_password = true` | RDS generates it and stores it in Secrets Manager; it never appears in code, tfvars or Terraform state |

## Legacy problem fixed
- #1 Hardcoded credentials: the target database password lives only in Secrets Manager

## What I learned
- RDS took 7m48s to create
- `engine_lifecycle_support` stops a database being enrolled in paid Extended Support by accident
- MySQL 8.4 uses a newer login method by default; the app's old `mysql` library will likely need replacing with `mysql2`

## Cost
About $0.02 to $0.03 an hour while running, plus about $0.40 a month for the secret
