# 08 – App code ready for RDS (mysql2 + connection pool)

## Goal
Make the app able to connect to RDS MySQL 8.4 and survive a database failover, before building the AWS app tier.

## What I changed (`app/app-tier`)
| Change | Why |
|---|---|
| `mysql` to `mysql2` | MySQL 8.4 uses a newer default login method the old library can't handle |
| Single connection to a connection pool, with up to 3 attempts on connection errors | Fixes legacy problem #3: broken connections are replaced, so the app can survive an RDS failover |
| Every query parameterized | Closed two more SQL injections found during the refactor |
| Errors caught per route and returned as 500 | One bad request can no longer crash the app |
| Settings from environment variables, with `DbConfig.js` as a fallback | On AWS the password will come from Secrets Manager, not a file |
| Removed `body-parser`, `node-fetch`, `os` | Unused; fewer dependencies to patch |
| Tagged the old code as `legacy-v1` | So the legacy server can stay on the original version |

## Tests
| Test | Result |
|---|---|
| MySQL 8.0 (local, via `DbConfig.js`) | Health, list, single lookup all work |
| `id=9999` | Clean "not found" message; app stays up (previously crashed) |
| Delete with `id = 0 OR 1=1` | Rejected; nothing deleted (previously would wipe the table) |
| MySQL 8.4 with its default login method (local, via environment variables) | Write and read succeed |

## What I learned
- Fixing one SQL injection isn't enough: search the whole codebase for the same pattern
- Testing against the exact target version locally (MySQL 8.4 in Docker) caught a problem for free, before it reached AWS

## Cost
$0
