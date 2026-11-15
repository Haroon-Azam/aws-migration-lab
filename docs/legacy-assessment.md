# Legacy application assessment

Findings from reviewing the app before migration. Each one will be addressed during modernization.

| # | Problem | Where | Risk | Planned fix |
|---|---|---|---|---|
| 1 | Hardcoded database credentials | `app-tier/DbConfig.js` | Password leaks through code or git | Move to AWS Secrets Manager |
| 2 | SQL injection | `app-tier/TransactionService.js` | Attacker can read or change data | Use parameterized queries |
| 3 | Single database connection, no reconnect | `app-tier/TransactionService.js` | App breaks during a database failover | Use a connection pool with retries |
| 4 | Outdated dependencies (8 known vulnerabilities) | `app-tier/package.json` | Known security holes | Update packages, run `npm audit` |
