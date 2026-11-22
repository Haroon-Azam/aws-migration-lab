# ADR 003: Outbound internet for the app tier

## Context
App servers run in private subnets with no internet route. At boot they must install packages, clone the app from GitHub and read the database password from Secrets Manager.

## Options
| Option | Pros | Cons |
|---|---|---|
| NAT Gateway | Managed, highly reliable, the standard pattern | About $0.045/hour plus data processing |
| NAT instance | Cheapest | I would have to patch and manage it |
| VPC endpoints only | Private access to AWS services | Can't reach GitHub; several endpoints cost more than one NAT |
| Public subnets for app servers | Free | Exposes servers; breaks the 3-tier design |

## Decision
One NAT Gateway in `public-a`, with the private route table's default route pointing to it.

## Consequences
- The lab is destroyed after each session, so the NAT costs cents per session, not $33 a month
- Single point of failure: if zone a fails, zone b servers lose outbound access. Production would use one NAT Gateway per zone.
- The database subnets share the private route table, so they also get an outbound route. RDS never starts outbound connections, and its firewall allows no inbound except from the app tier, so the risk is low; a stricter setup would give the database subnets their own route table.
