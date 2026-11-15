# ADR 001: Region

## Context
The app serves a Canadian business, and I am based in Montreal.

## Decision
Use `ca-central-1` (Montreal) for all resources.

## Consequences
- Data stays in Canada, which matters for Canadian privacy expectations
- Low latency for Canadian users
- Prices are slightly higher than `us-east-1`, which I accept
