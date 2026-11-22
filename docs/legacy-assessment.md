# Legacy application assessment

Findings from reviewing the app before migration. Each one will be addressed during modernization.

| # | Problem | Where | Risk | Planned fix |
|---|---|---|---|---|
| 1 | Hardcoded database credentials | `app-tier/DbConfig.js` | Password leaks through code or git | Move to AWS Secrets Manager |
| 2 | SQL injection | `app-tier/TransactionService.js` | Attacker can read or change data | Use parameterized queries |
| 3 | Single database connection, no reconnect | `app-tier/TransactionService.js` | App breaks during a database failover | Use a connection pool with retries |
| 4 | Outdated dependencies (8 known vulnerabilities) | `app-tier/package.json` | Known security holes | Update packages, run `npm audit` |

**Status update (2026-11-15):** problem #2, SQL injection, fixed before migration with a parameterized query and verified by re-running the attack.

**Status update (2026-11-15):** problem #4, outdated dependencies, fixed with `npm audit fix` (8 vulnerabilities to 0) and re-tested.

**Status update (2026-11-22):**
- Problem #3, no reconnect: fixed in code. Switched from `mysql` to `mysql2` with a connection pool and up to 3 attempts on connection errors. Failover behaviour will be proven on RDS Multi-AZ in the break-it phase.
- Found two more SQL injections while refactoring: `findTransactionById` and `deleteTransactionById` pasted `id` into the SQL. A delete with `id = 0 OR 1=1` would have wiped the table. Fixed with placeholders; verified that the same request now deletes nothing.
- Found two crash bugs: `throw err` inside database callbacks, and `/transaction/id` reading `result[0]` when nothing matched. Both now return an error response and the app keeps running.
