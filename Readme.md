# Fora Real Estate Office

PHP 8.1+ and MySQL property and tenancy management starter for the Fora Real Estate Office.

## Setup

1. Create a MySQL database named `myshop` and import `database/schema.sql`.
   If you already installed an earlier version of Fora, run migrations in order: `20261107_preserve_renewal_history.sql`, `20261108_add_tenant_code.sql`, `20261109_rent_vat_billing.sql`, then `20261110_receipt_details.sql`, and `20261111_real_estate_vat_treatment.sql`, then `20261130_mobile_cheque_register.sql`, `20261201_mobile_cheque_accounting.sql`, `20261202_mobile_wallet_transfer.sql`, `20261203_mobile_sales_returns.sql`, and `20261204_mobile_purchase_cheques.sql`, and `20261205_mobile_device_specs_barcodes.sql`, then `20261216_mobile_customer_wallet_payments.sql` and `20261218_company_access_remove.sql`, `20261219_company_demo_period.sql`, `20261220_company_demo_plan.sql`, and `20261221_company_user_limit.sql`, and `20261222_mobile_purchase_vat.sql`, and `20261223_mobile_wallet_opening_balance.sql` (each once). Apply the VAT treatment migration to an existing database before using the Real Estate VAT report.
2. Set your MySQL username and password in `config.example.php` (the included `config.php` loads those values).
3. Serve this directory with Apache/PHP (for example, XAMPP) and open it in a browser.
4. Sign in with the initial account `admin` / `ChangeMe123!`, then create your own staff accounts and change the initial password immediately.

Uploaded documents and photos are stored in `uploads/`; keep that directory writable by PHP and protect it from script execution in production.

## Included

Dashboard, secure login/session handling, a Real Estate category with editable property and room inventory, direct rent actions from available units, tenants and tenancy records with automatic unique tenant codes, property-based VAT treatment and exact cash/cheque allocation, cheque date and bank/number validation, draft Commission and Security receipts, a Billing module for new bills, renewals saved as separate tenancy records with full history, cancellations with outstanding cheque/rent checks, staff accounts, filters, optional document/photo uploads, and a reserved Shop category.

This is a self-hosted starter. Configure HTTPS, database credentials, backups, and deployment access controls before using real tenant identity documents.

For an existing database with Grocery enabled, run database/migrations/20261114_grocery_customer_building_flat.sql once to add the customer Building Name / Flat No. field.

For Lifetime subscription mode, run database/migrations/20261224_company_lifetime_subscription.sql once on existing databases.

For the Office First Client directory, run database/migrations/20261225_office_first_clients.sql once on existing databases. Then enable Office for a company in Super Admin → Company access.

Office First Client setup: run database/migrations/20261225_office_first_clients.sql once on existing databases, then enable Office for each company from Super Admin → Company access.

Office work items, reusable service packages, and Office bills: run database/migrations/20261226_office_work_packages_bills.sql once on existing databases.

Office bill VAT, discount, payment, and package-based layout: run database/migrations/20261227_office_billing_fields.sql once on existing databases.

Office bill applicant name field: run database/migrations/20261228_office_applicant_name.sql once on existing databases.
