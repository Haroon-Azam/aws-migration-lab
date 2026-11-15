# ADR 002: Target MySQL version

## Context
The legacy server runs MySQL 8.0. MySQL 8.0 reached community end of life in April 2026, and RDS for MySQL 8.0 left standard support on July 31, 2026. RDS now charges Extended Support fees for 8.0.

## Decision
Use RDS for MySQL 8.4, the long-term support version, and disable Extended Support enrollment.

## Consequences
- The migration also upgrades the database version, a real-world reason companies migrate
- No surprise Extended Support charges
- MySQL 8.4 uses a newer default login method; the app's old `mysql` library may need upgrading to `mysql2` before it can connect
- DMS must copy from MySQL 8.0 to 8.4, a version change to test carefully
