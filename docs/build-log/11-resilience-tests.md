# 11 – Resilience tests (break it on purpose)

## Goal
Prove the target architecture recovers from failure without a human, while a script hit the app through the load balancer every second.

## Setup changes
- RDS converted to Multi-AZ (`db_multi_az = true`). The conversion took about 7 minutes with no downtime.
- App servers now create the table at boot with `CREATE TABLE IF NOT EXISTS` (schema as code), so a fresh RDS works without DMS.

## Test 1: terminate one app server
- Killed one of the 2 servers in the console.
- About 20 seconds of partial errors (7 of about 22 requests: 502s and timeouts) while the load balancer still sent every second request to the dead server.
- Health checks (15 s interval, 3 failures) marked it unhealthy, then all traffic went to the healthy server.
- The Auto Scaling Group launched a replacement automatically. No human action.

## Test 2: forced RDS Multi-AZ failover
- `aws rds reboot-db-instance --force-failover`
- AWS events: failover started 00:08:33 UTC, completed 00:09:03 UTC (about 30 seconds).
- The app saw about 13 seconds of errors (3 timeouts), then recovered on its own. rows=3 throughout, so no data lost.
- No app restart. The `mysql2` pool with retries reconnected to the new primary. This closes legacy problem #3 (the old library crashed on a lost connection).

## Scorecard
| Test | User-facing errors | Recovery | Human action |
|---|---|---|---|
| App server killed | ~20 s, 7 of ~22 requests | Load balancer routed around it, ASG replaced it | None |
| Database failover | ~13 s, 3 requests | Standby promoted, pool reconnected | None |

## Problems hit along the way
- POST and GET returned 500. `journalctl -u transactions-api` showed `ER_NO_SUCH_TABLE`, and `/var/log/app-setup.log` showed the servers had run the old script. The first time, I had run the rewrite from `infra\migration`, so the new script landed in the wrong folder (found later and removed). Fixed the file, applied, and instance refresh replaced both servers with zero downtime.
- `multi_az` was still false for the same reason (tfvars line never saved). Lesson: verify a file change with `Select-String` before applying.
- A second reboot command was refused with `InvalidDBInstanceState` because the database was already rebooting.
- The API's `AvailabilityZone` field lagged behind the real failover. RDS events are the source of truth.

## What I'd improve
- Faster health checks (5 s interval, 2 failures) to roughly halve the crash detection window
- Client retry on 502 to hide the blip from a sudden crash
- Planned removals always go through the ASG (deregister, drain, then terminate), which is how instance refresh got zero errors
