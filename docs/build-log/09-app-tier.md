# 09 – App tier: load balancer and Auto Scaling Group

## Goal
Run the modernized app in the target VPC across two zones, reading from RDS.

## What I built (Terraform, `infra/target`)
| Resource | Setting | Why |
|---|---|---|
| NAT Gateway (ADR 003) | One, in `public-a` | Private app servers can install packages, clone from GitHub and reach Secrets Manager |
| Load balancer | Public subnets in both zones, HTTP from my IP only | Single front door; health checks `/health` every 15 seconds |
| App security group | Port 4000 only from the load balancer's security group | Servers can't be reached directly |
| App IAM role | Session Manager, plus `GetSecretValue` on the one RDS secret | Least privilege; no stored keys |
| Launch template | Amazon Linux 2023, IMDSv2, startup script | Each server clones `main`, reads the RDS password from Secrets Manager into a root-only settings file, and runs the app with systemd |
| Auto Scaling Group | 2 servers (one per zone), ELB health checks, rolling instance refresh | Self-healing; replaced automatically if unhealthy |

## Result
Through the load balancer: health check OK, and the 3 rows migrated by DMS read back from RDS MySQL 8.4.

## Findings
- Confirmed the DMS gap: RDS has `id int NOT NULL` with the primary key but no `AUTO_INCREMENT`. New inserts would fail. Fix goes in the cutover runbook.
- The normal Session Manager user got "Permission denied" on the settings file: the root-only protection works.
- Lesson: bash runs commands; SQL only runs inside `mysql`.

## Notes
No writes to the new app yet: DMS is still syncing from the legacy database, and writing to both would split the data.

## Cost
NAT + load balancer + 2 servers: about $0.12 an hour on top of RDS, DMS and the legacy server
