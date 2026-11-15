# 05 – Target network (2 zones, 3 tiers)

## Goal
Build the new AWS home for the app, designed to survive the loss of one data centre.

## What I built (Terraform, `infra/target`)
| Tier | Zone a | Zone b | Internet route |
|---|---|---|---|
| Public (load balancer) | `10.1.1.0/24` | `10.1.2.0/24` | Yes, via Internet Gateway |
| App (servers) | `10.1.11.0/24` | `10.1.12.0/24` | No |
| Database (RDS) | `10.1.21.0/24` | `10.1.22.0/24` | No |

- VPC `10.1.0.0/16`, chosen not to overlap on-prem (`10.0.0.0/16`) so the two can be connected for DMS
- One public and one private route table; the private one has only the local route

## Decisions
- No NAT Gateway yet: about $33 a month even when idle. The cheapest way to give app servers outbound access will be decided when I build the app tier.

## What I learned
- `locals` + `for_each` built 6 subnets and 6 route associations from one table
- A one-line condition (`tier == "public" ? ... : ...`) picked the route table and public IP setting per subnet

## Cost
$0
