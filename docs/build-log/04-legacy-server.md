# 04 – Legacy server (simulated on-prem)

## Goal
Run the whole legacy app on one server inside the on-prem network, built entirely from code.

## What I built (Terraform, `infra/onprem`)
| Resource | Purpose |
|---|---|
| Security group | Port 4000 from my IP only; no SSH port open |
| IAM role + instance profile | Lets the server use Session Manager without stored keys |
| EC2 t3.micro, Amazon Linux 2023 | The legacy server; AMI looked up with a data source, not hard-coded |
| User data script (`user-data.sh.tftpl`) | On first boot: installs Docker, Git, Node.js; runs MySQL 8.0 with binary logging; seeds data; clones the app from GitHub; runs it as a systemd service |

## Hardening choices
- No SSH: shell access through Session Manager only
- IMDSv2 required (`http_tokens = "required"`)
- Encrypted disk
- Password passed as a sensitive Terraform variable; script avoids `set -x` so it never reaches logs

## Result
API answered on port 4000 about 4 minutes after `apply`: health check, 3 seeded rows, and a new write.

## What I learned
- A data source reads from AWS instead of creating anything
- Terraform templates fill in variables before the script is sent
- MySQL binary logging must be on for DMS to copy live changes later

## Cost
About $0.02 an hour while running; destroyed at the end of the session
