# Databricks DLT / Lakeflow Medallion Demo

An end-to-end, **SQL-based** Databricks Lakeflow Spark Declarative Pipelines demo (formerly Delta Live Tables / DLT): **Auto Loader → Bronze → Silver (expectations) → Gold**, with an incremental second file and a deployable Declarative Automation Bundle (formerly Databricks Asset Bundle).

> **Status:** Source code and bundle configuration are provided. You must run and validate the pipeline in your own Databricks workspace. No workspace run is claimed here.

## Project contents

```text
databricks-dlt-medallion-demo/
├── databricks.yml               # bundle entrypoint; dev target
├── resources/
│   └── dlt_pipeline.yml         # pipeline deployment definition
├── sql/
│   ├── 00_setup.sql             # ONE-TIME SQL EDITOR SETUP (not pipeline code)
│   ├── 01_bronze.sql            # pipeline: Auto Loader streaming ingestion
│   ├── 02_silver.sql            # pipeline: built-in quality expectations
│   ├── 03_gold.sql              # pipeline: materialized daily sales view
│   └── 04_validate.sql          # SQL EDITOR validation (not pipeline code)
├── data/
│   ├── orders_001.csv           # first batch
│   └── orders_002.csv           # incremental second batch
├── docs/
│   ├── ARCHITECTURE.md
│   └── screenshots/             # add your successful run screenshots
└── .gitignore
```

## Requirements

- A Databricks workspace with **Unity Catalog** and **Lakeflow Spark Declarative Pipelines** enabled. This example uses **serverless pipeline compute**; check your workspace/edition supports it. Free Edition availability and permissions may differ.
- Permission to create schema/volume in existing catalog `main`, and create/use a pipeline.
- A SQL warehouse or SQL editor for setup/verification.
- For CLI deployment: current Databricks CLI (`databricks`), authentication to your workspace, and appropriate permissions.
- CSV input represents **append-only** orders; use AUTO CDC for updates/deletes instead.

**Fixed names in this beginner demo:** catalog `main`, schema `dlt_orders_demo`, volume `landing`, input folder `/Volumes/main/dlt_orders_demo/landing/orders/`. If `main` is unavailable, change **all** occurrences in `sql/00_setup.sql`, `sql/01_bronze.sql`, `sql/04_validate.sql`, and `resources/dlt_pipeline.yml` before deploying.

## Step 1 — Set up Unity Catalog (one time)

In a normal Databricks **SQL editor**, run `sql/00_setup.sql`:

```sql
CREATE SCHEMA IF NOT EXISTS main.dlt_orders_demo;
CREATE VOLUME IF NOT EXISTS main.dlt_orders_demo.landing;
```

In Catalog Explorer, open `main` → `dlt_orders_demo` → `landing`. Create folder `orders` under the volume. Upload **only** `data/orders_001.csv` into it. Confirm the file path:

```text
/Volumes/main/dlt_orders_demo/landing/orders/orders_001.csv
```

**Do not upload `orders_002.csv` yet**; it is the incremental test.

## Step 2A — Deploy the pipeline with Databricks CLI (recommended for GitHub)

From your extracted project root on your Mac:

```bash
databricks version
databricks auth login --host https://YOUR-WORKSPACE-HOST
databricks auth profiles
databricks bundle validate -t dev
databricks bundle deploy -t dev
databricks bundle run dlt_orders_pipeline -t dev
```

Use your workspace URL in place of `https://YOUR-WORKSPACE-HOST`. If you have multiple CLI profiles, select the intended profile using `--profile PROFILE_NAME` on the bundle commands or set `DATABRICKS_CONFIG_PROFILE`. `bundle run` triggers an update; confirm completion and metrics in **Jobs & Pipelines**. Do **not** store access tokens in this repository.

The deployment consists of:

- `databricks.yml`: the bundle root and `dev` target.
- `resources/dlt_pipeline.yml`: a **triggered**, serverless pipeline publishing into `main.dlt_orders_demo` and sourcing the three SQL transformation files.
- `sql/01_bronze.sql`, `sql/02_silver.sql`, `sql/03_gold.sql`: actual pipeline source code.

### Step 2B — Alternative: create in the Databricks UI

If CLI/serverless is not available but the workspace supports a compatible Lakeflow pipeline, select **Jobs & Pipelines → Create ETL pipeline**, name it `dlt_orders_pipeline`, set catalog `main` and schema `dlt_orders_demo`, and add **only** `01_bronze.sql`, `02_silver.sql`, `03_gold.sql` as SQL source files. Select supported compute, use triggered mode, and run.

**Do not add** `00_setup.sql` or `04_validate.sql` as pipeline sources. If you deploy the bundle, you do not also need to create the same pipeline manually.

## Step 3 — Validate the initial run

Run `sql/04_validate.sql` in a normal Databricks SQL editor. Expected values from `orders_001.csv`:

| Layer | Expected |
|---|---|
| Bronze | **8 rows** |
| Silver | **5 rows** (order IDs 101, 103, 104, 106, 108) |
| Gold | 2026-10-28 USA: **2 orders / 750**; 2026-10-29 India: **1 / 300**; 2026-10-29 USA: **2 / 275** |

Silver expectations exclude invalid/nonqualifying orders (e.g. amount <= 100). Inspect the Silver table metrics in the pipeline monitoring UI. The expectation `valid_amount` is set to **DROP ROW**.

## Step 4 — Test incremental processing

1. Upload `data/orders_002.csv` to the **same** volume folder with its original distinct filename.
2. Trigger another **normal** pipeline update (not a full refresh):

   ```bash
   databricks bundle run dlt_orders_pipeline -t dev
   ```

   Or click **Run pipeline** in Databricks.
3. Run `sql/04_validate.sql` again. Expected results:

| Layer | Expected after both files |
|---|---|
| Bronze | **12 rows** |
| Silver | **8 rows** |
| Gold additions | 2026-10-30 India: **1 / 200**; 2026-10-30 USA: **2 / 575** |

Auto Loader tracks processed files so a regular incremental update discovers the second file without appending the first batch again. This is **not** SCD Type 1/2 or row-level CDC.

## Step 5 — Capture screenshots for your GitHub portfolio

After a successful run, add screenshots to `docs/screenshots/` and link them from README. Suggested filenames appear in `docs/ARCHITECTURE.md`. Never commit credentials or private business data.

## Step 6 — Sync your local project to GitHub

For repository: <https://github.com/ritasebastian/databricks-dlt-medallion-demo>

If this is a new local folder (no `.git` directory), connect it to your existing GitHub repo:

```bash
cd ~/Downloads/databricks-dlt-medallion-demo
git init
git branch -M main
git remote add origin https://github.com/ritasebastian/databricks-dlt-medallion-demo.git
git add .
git commit -m "Add deployable Lakeflow DLT demo with bundle configuration"
git push -u origin main
```

If you already cloned or initialized this repository, **copy the updated project files into that existing working tree**, then run:

```bash
git status
git add .
git commit -m "Add Databricks bundle pipeline definition and documentation"
git push origin main
```

If `origin` already exists, do not add it again. If the remote has commits not present locally, first sync/reconcile them (such as with `git pull --rebase origin main`) rather than force-pushing.

## Troubleshooting

| Problem | What to check |
|---|---|
| `catalog main not found` | Change the catalog consistently in setup, Bronze, validation, and pipeline YAML |
| `PERMISSION_DENIED` creating volume/schema | Request `USE CATALOG`, `CREATE SCHEMA`, `CREATE VOLUME`, and pipeline/compute permissions as applicable |
| No files ingested | Check exact folder path and that only the first CSV was uploaded initially |
| CLI bundle validation fails | Update Databricks CLI; confirm you're in folder containing `databricks.yml`, and inspect auth profile/host |
| Serverless not available | Use compatible compute in a manually created pipeline; bundle configuration targets serverless |
| Duplicate input | Avoid re-uploading the same records under different filenames; file-based incremental ingestion is not order-ID deduplication |
| Expectation drops rows | Review `orders_silver` rules and the original CSV amounts |

## Documentation

- [Pipeline architecture](docs/ARCHITECTURE.md)
- [Databricks bundle resource reference](https://docs.databricks.com/aws/en/dev-tools/bundles/resources)
- [Databricks pipeline bundle tutorial](https://docs.databricks.com/aws/en/dev-tools/bundles/pipelines-tutorial)

## Learning outcomes

Delta Lake tables, Auto Loader, streaming tables, Lakeflow pipeline SQL, data quality expectations, materialized views, Declarative Automation Bundles, incremental updates, and GitHub version control.
