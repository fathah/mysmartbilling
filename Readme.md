# Fora Real Estate Office

PHP 8.1+ and MySQL property and tenancy management starter for the Fora Real Estate Office.

## Setup

1. Copy `config.example.php` to `config.local.php` and set your MySQL host, database, username, and password there. Git ignores `config.local.php`.
2. On shared hosting, create an empty MySQL database in the hosting control panel and enter its credentials in `config.local.php`. Set a strong `migration_password` in that file, open `/migrate.php` over HTTPS, enter the password, and choose **Apply pending migrations**. With command-line access, `php database/migrate.php init` can create the configured database and apply the migrations. The database user needs migration privileges. Fresh installations use the initial migration and incremental SQL files.
3. Serve this directory with Apache/PHP (for example, XAMPP) and open it in a browser.
4. Sign in with the initial account `admin` / `ChangeMe123!`, then create your own staff accounts and change the initial password immediately.

Uploaded documents and photos are stored in `uploads/`; keep that directory writable by PHP and protect it from script execution in production.

## Included

Dashboard, secure login/session handling, a Real Estate category with editable property and room inventory, direct rent actions from available units, tenants and tenancy records with automatic unique tenant codes, property-based VAT treatment and exact cash/cheque allocation, cheque date and bank/number validation, draft Commission and Security receipts, a Billing module for new bills, renewals saved as separate tenancy records with full history, cancellations with outstanding cheque/rent checks, staff accounts, filters, optional document/photo uploads, and a reserved Shop category.

This is a self-hosted starter. Configure HTTPS, database credentials, backups, and deployment access controls before using real tenant identity documents.

## Database migrations

After uploading or deploying the code, open `/migrate.php` and enter the `migration_password` from the hosting server's `config.local.php`. Choose **View migration status** or **Apply pending migrations**. Each deployment runs pending files through this protected endpoint or the CLI command `php database/migrate.php deploy`.

The password is submitted in the POST body. Keep it in the ignored `config.local.php`. The endpoint stays disabled while the password is empty. Every action requires the password, and migration results are returned only after authentication. Serve the endpoint over HTTPS.

A deployment service can send a form-encoded POST with `action=deploy` and `password` after uploading the code. Set `Accept: application/json` for JSON results, including `ok`, `error`, `last_completed_migration`, and the migration list. For example, with the password available as a deployment environment variable, use the following command.

```sh
curl --fail-with-body --request POST \
  --header 'Accept: application/json' \
  --data-urlencode "password=$MIGRATION_PASSWORD" \
  --data-urlencode 'action=deploy' \
  'https://your-domain.example/migrate.php'
```

Use the app's deployment path in the URL if it is hosted in a subdirectory. A successful deploy returns HTTP 200. Invalid credentials return 401, invalid actions or parameters return 400, migration failures return 500, and an unconfigured password returns 503.

Run `php database/migrate.php status` to list migration status and the last completed file. The `schema_migrations` table stores each filename, SHA-256 checksum, status, start/completion timestamps, and failure details. A MySQL advisory lock serializes migrations across concurrent requests and deployment processes.

Add new `.sql` files under `database/migrations/` using increasing timestamp prefixes, such as `202612310001_add_customer_field.sql`. New files run in filename order after the historical migrations. `database/migration_order.php` preserves the existing dependency order, including the grocery table creation and purchase-order specifications exceptions. Preserve applied files and their order. Make subsequent changes in a new migration. SQL runs against the database selected in `config.local.php`. Use plain MySQL SQL, including multiple statements. Client commands such as `DELIMITER`, `SOURCE`, and `USE` belong outside migration files.

### Existing installations

An existing database without migration history needs a one-time baseline. After verifying the migrations already applied, run `php database/migrate.php baseline <last-applied-file.sql>`. This records the history through that file without executing its SQL, then future deploys apply the remaining files. For example, a database already updated through every current migration uses `php database/migrate.php baseline 20261230_office_client_wallet_entries.sql`.

An installation with only the original pre-migration schema uses `php database/migrate.php baseline 20261106_initial_schema.sql`. The older `database/schema.sql` snapshot includes some later schema changes, so installations imported from that snapshot need their actual schema reconciled with the migration sequence before choosing a baseline. The migrator requires a verified starting history for existing installations. From the browser, choose **Record existing migration history**, enter the last applied filename, and submit with the password. This performs the same baseline operation as the CLI command.

### Failure recovery

MySQL DDL can commit before a later statement fails. Failed or interrupted migrations block subsequent deploys until repaired. Inspect `schema_migrations.error_message` and the database, then choose the resolution matching the repair performed.

- After manually completing every change in the failed file, run `php database/migrate.php resolve <file.sql> applied`.
- After manually undoing the partial changes, run `php database/migrate.php resolve <file.sql> rolled-back`, then run `php database/migrate.php deploy` to retry.

For browser recovery, choose **Resolve a repaired migration**, enter the filename, select the resolution matching the manual repair, and submit with the password.

Checksums catch edits to recorded migration files. Restore the original file before resolving failures. A connection failure or terminated process can leave the status as `running`, which uses the same recovery procedure.

Run `php tests/migrations.php` to verify fresh installation, dependency order, repeated deployment, failure recovery, checksum validation, and baselining using disposable databases on the configured MySQL server. The test account needs permission to create and drop its temporary databases.

Run `php tests/migration_endpoint.php` to verify the browser form, password enforcement, HTTP deployment, baselining, and recovery through a temporary local HTTP server and disposable database.

After migrations complete, enable Office or Grocery for the relevant companies from Super Admin → Company access.
