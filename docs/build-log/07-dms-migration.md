# 07 – Data migration with DMS

## Goal
Copy the legacy database into RDS and keep it in sync, so cutover needs only minimal downtime.

## What I built (Terraform, `infra/migration`)
| Resource | Purpose |
|---|---|
| VPC peering + 2 routes | Private link between on-prem (`10.0.0.0/16`) and target (`10.1.0.0/16`) |
| Legacy server firewall rule | MySQL 3306 from the target app subnets only |
| `dms-vpc-role` | Role DMS needs to run inside a VPC (exact name required) |
| DMS replication instance (`dms.t3.small`) | Runs in the target app subnets, so RDS already allows it |
| Source endpoint | Legacy MySQL 8.0 at its private IP, over the peering |
| Target endpoint | RDS MySQL 8.4, credentials read from Secrets Manager |
| Replication task | `full-load-and-cdc` on every table in `webappdb` |

## Result
- Both endpoint connection tests succeeded
- Full load: 4 rows in under 1 second
- CDC: a row written to the legacy app during the migration appeared in RDS (Inserts: 1, Total rows: 5)

## Problems and fixes
| Problem | Cause | Fix |
|---|---|---|
| Peering route would be removed by `infra/onprem` | Its route table defines routes inline, so Terraform owns every route | Added `lifecycle { ignore_changes = [route] }` |
| `Invalid ReplicationInstance class` | `dms.t3.micro` is not offered in `ca-central-1` | Listed what the region offers with `describe-orderable-replication-instances`; used `dms.t3.small` |
| Duplicate resource error | `Add-Content` appended the task block three times | Rewrote the file with `Set-Content`, which gives the same result however many times it runs |

## What I learned
- Separate Terraform folders can share infrastructure through data sources, without merging into one project
- Some changes update in place (firewall rules); others replace a resource. Check the plan every time.
- DMS copies data but not every table detail (such as `AUTO_INCREMENT`), so the target table must be checked before cutover

## Cost
DMS about $0.04 an hour while running; destroyed at the end of the session
