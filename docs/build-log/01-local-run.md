# 01 – Running the legacy app locally

## Goal
Run the legacy three-tier app and its database on my laptop before touching AWS, so I understand what I'm migrating.

## What I did
- Ran MySQL 8.0 in Docker and created the `transactions` table with one seed row
- Copied the app code from the AWS three-tier workshop into `app/`
- Pointed the app tier at the local database and started it with Node.js
- Tested `/health`, `GET /transaction` and `POST /transaction` with curl

## What broke and how I fixed it
| Problem | Cause | Fix |
|---|---|---|
| `npm` blocked in PowerShell | Windows execution policy blocks scripts by default | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| `Cannot find module 'mysql'` | `npm install` never ran because of the problem above | Re-ran `npm install` after the fix |
| App couldn't log in to MySQL 8 | Old `mysql` library doesn't support MySQL 8's default login method | Started MySQL with `--default-authentication-plugin=mysql_native_password` |
| `.gitignore` had no effect | Created in `app/app-tier/` instead of the repo root | Moved it to the root and deleted the stray file |
| Database password committed | `DbConfig.js` was added before it was ignored | Ignored it, added `DbConfig.example.js`, rewrote the commit with `--amend` before pushing |

## Result
The app reads and writes to MySQL through its API.

## Cost
$0

## Security demo: SQL injection
- Sent `1', (SELECT user())) -- ` as the amount in POST /transaction
- The app pasted it straight into its SQL, so `SELECT user()` ran and saved the database username (`root@172.17.0.1`) as the description
- Read it back with GET /transaction: one request leaked internal data with no password needed
- Evidence: `docs/screenshots/phase1-sql-injection.png`

## Fix: parameterized query
- Changed `addTransaction` to send SQL and values separately: `VALUES (?, ?)` with `[amount, desc]`
- Re-ran the same attack: the text was stored as plain data and no command ran
- Evidence: `docs/screenshots/phase1-sql-injection-fixed.png`

## Fix: outdated dependencies
- `npm audit` found 8 vulnerabilities (1 critical, 4 high), mostly in Express and its sub-packages
- Ran `npm audit fix` (safe updates only, no `--force`, since that would jump major versions and could break the app)
- Only `package-lock.json` changed: the fixed versions were still inside the ranges in `package.json`
- Result: 0 vulnerabilities; restarted the app and re-tested health, read and write
