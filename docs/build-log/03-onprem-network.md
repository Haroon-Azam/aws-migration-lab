# 03 – On-prem network (simulated data centre)

## Goal
Build a separate network that plays the role of the company's own data centre.

## What I built (Terraform, `infra/onprem`)
| Resource | Setting | Why |
|---|---|---|
| VPC | `10.0.0.0/16` | Private network; must not overlap the AWS target (`10.1.0.0/16`) so the two can be connected later |
| Subnet | `10.0.1.0/24` in `ca-central-1a`, public IPs on | One floor for the legacy server, reachable from my laptop |
| Internet Gateway | attached to the VPC | The network's door to the internet |
| Route table | `0.0.0.0/0` to the gateway | Sends internet traffic out through the door |
| Association | route table to subnet | Makes the subnet public |

## What I learned
- Terraform worked out the build order from the references in my code (the dependency graph) and built independent pieces in parallel.
- `tags` is what I set on a resource; `tags_all` adds the provider's default tags.
- AWS automatically adds a default route table, security group and network ACL to every VPC.
- Simplification: a real on-prem server would sit behind a firewall; this one is public so I can reach it.

## Cost
$0 (networking pieces are free)
