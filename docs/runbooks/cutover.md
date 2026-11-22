# Runbook: cutover from legacy server to AWS

## Goal
Move users from the legacy app (MySQL 8.0) to the AWS app tier (RDS MySQL 8.4) with no data loss and minimal downtime.

## Pre-checks (before downtime starts)
1. DMS task `legacy-to-rds` shows "Load complete, replication ongoing"
2. New app is healthy through the load balancer (`/health`)
3. Legacy and new app return the same rows

## Cutover steps
| # | Step | How |
|---|---|---|
| 1 | Last write on legacy | POST a "last write before cutover" row to the legacy app |
| 2 | **Downtime starts:** freeze writes | Stop the legacy app service (`systemctl stop legacy-app`) |
| 3 | Confirm DMS caught up | The last row appears when reading through the new app |
| 4 | Stop replication | Stop the DMS task, so nothing else writes to RDS |
| 5 | Fix schema gap | `ALTER TABLE transactions MODIFY id INT NOT NULL AUTO_INCREMENT` on RDS |
| 6 | Smoke test | POST "first write after cutover" through the load balancer and read it back |
| 7 | **Downtime ends:** switch users | Users now use the load balancer URL |

## Rollback plan
- **Before step 6 succeeds:** restart the legacy app (`systemctl start legacy-app`) and send users back to it. No data is lost, because no writes have gone to RDS yet.
- **After real users write to RDS:** rolling back would need those new rows copied back to the legacy database (a reverse DMS task). This is the point of no return, so step 6 must pass first.

## In production I would also
- Lower the DNS record's TTL a day before, then switch the DNS name from the old server to the load balancer, so users follow automatically
- Announce a maintenance window and show a maintenance page during the freeze

## Execution log (2026-11-22)
| Time | Step | Result |
|---|---|---|
| Before | Pre-checks | DMS "Load completed, replication ongoing"; legacy and new app both returned the same 3 rows |
| Before | Last write on legacy | Row 4 "last write before cutover" |
| 5:14:47 PM | **Freeze**: stopped `legacy-app` | Legacy health check failed (expected) |
| +~30 s | DMS caught up | Row 4 visible through the new app |
| | Stopped DMS task | Status: Stopped |
| | Schema fix | `id int NOT NULL AUTO_INCREMENT`, `AUTO_INCREMENT=5` |
| | Smoke test | "first write after cutover" saved as id 5 |
| +215 s | **Downtime ends** | Users on the load balancer |

**RTO: 215 seconds. RPO: 0.** Most of the downtime was manual steps; scripting them would bring it under a minute.
