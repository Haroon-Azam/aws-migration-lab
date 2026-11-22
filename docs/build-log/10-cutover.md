# 10 – Cutover

## Result
Moved from the legacy server (MySQL 8.0) to the AWS app tier (RDS MySQL 8.4) following `docs/runbooks/cutover.md`.
- Downtime (RTO): 215 seconds
- Data lost (RPO): 0
- Rollback was available until the first write to RDS succeeded

## What made it low-risk
- DMS kept RDS in sync while the old app served users, so the freeze only had to wait seconds for the last changes
- The schema gap (`AUTO_INCREMENT`) was found during testing and fixed inside the window, before any write
- Pre-checks proved both systems returned the same data before the clock started

## What I'd improve
- Script the cutover steps to cut downtime to under a minute
- Use a DNS name with a low TTL so users switch without changing URLs
