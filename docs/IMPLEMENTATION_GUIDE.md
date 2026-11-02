# Complete implementation guide — Databricks Medallion demo

**Workspace browser link:** https://dbc-431999de-fcdd.cloud.databricks.com/?o=7474657393830870  
**CLI host (do not include `?o=...`):** `https://dbc-431999de-fcdd.cloud.databricks.com`  
**Workspace configuration:** already set in `databricks.yml` under `targets.dev.workspace.host`.

This project runs **CSV files → Auto Loader → Bronze streaming table → Silver streaming table (quality filters) → Gold materialized view**. It is a file-incremental **append-only** demo, **not CDC/SCD Type 1/Type 2**. It uses sample orders dated October 2026, and its valid amount criterion is `amount > 100` (not `>= 100`).

## 1. Download and extract the project on your Mac

If you downloaded the ZIP to `~/Downloads`:

```bash
cd ~/Downloads
unzip databricks-dlt-medallion-demo-updated.zip
cd databricks-dlt-medallion-demo-main
ls -la
```

If your ZIP is named differently or extracted elsewhere, adjust the paths. The repo root is the folder with `databricks.yml`.

## 2. Open your workspace and confirm prerequisites

Open https://dbc-431999de-fcdd.cloud.databricks.com/?o=7474657393830870 and sign in.

Check that **Catalog Explorer**, **SQL Editor / SQL warehouse**, and **Jobs & Pipelines / Lakeflow Spark Declarative Pipelines** are available. You need permission to use or create the `main` catalog's schema, managed volume, and pipeline. The bundle specifies **serverless** pipeline compute; ensure your workspace supports it. If the `main` catalog is not present, replace `main` consistently in these files before deploying:

- `sql/00_setup.sql`
- `sql/01_bronze.sql`
- `sql/04_validate.sql`
- `resources/dlt_pipeline.yml`

## 3. Create Unity Catalog schema and volume (once)

In **SQL Editor → New query**, run:

```sql
CREATE SCHEMA IF NOT EXISTS main.dlt_orders_demo;
CREATE VOLUME IF NOT EXISTS main.dlt_orders_demo.landing;
```

This is the exact content of `sql/00_setup.sql`; do **not** add it as a pipeline source.

In **Catalog Explorer → main → dlt_orders_demo → Volumes → landing**, create folder **`orders`**. Upload **only** `data/orders_001.csv` first. The expected source path is:

```
/Volumes/main/dlt_orders_demo/landing/orders/orders_001.csv
```

Do **not** upload `orders_002.csv` until after validating the first run. If the folder already contains the second file from an earlier test, use a clean test location or remove the old demo files/checkpoints safely before following first-run expectations; deleting source files alone does not reset an existing streaming checkpoint.

## 4. Install Databricks CLI on Mac

Open **Terminal**:

```bash
databricks version
```

If CLI is not installed and Homebrew is installed:

```bash
brew tap databricks/tap
brew install databricks
```

If Homebrew is not installed, first install it from https://brew.sh/ or follow Databricks' supported CLI installation instructions.

## 5. Log in to *this workspace* using CLI

Use the host **without** the browser's `?o=...` query parameter:

```bash
databricks auth login --host https://dbc-431999de-fcdd.cloud.databricks.com --profile medallion-demo
databricks auth profiles
databricks current-user me --profile medallion-demo
```

Complete the browser authorization when prompted. The `--profile medallion-demo` name is only a local CLI profile, not an account login. **Never** put secrets, tokens, or your `~/.databrickscfg` in GitHub.

To use this profile for bundle commands in the current Terminal session:

```bash
export DATABRICKS_CONFIG_PROFILE=medallion-demo
```

## 6. Validate and deploy bundle

In the extracted project root:

```bash
cd ~/Downloads/databricks-dlt-medallion-demo-main
export DATABRICKS_CONFIG_PROFILE=medallion-demo

databricks bundle validate -t dev
databricks bundle deploy -t dev
databricks bundle summary -t dev
```

The bundle config lives in `databricks.yml` and `resources/dlt_pipeline.yml`, and reads **only** `sql/01_bronze.sql`, `sql/02_silver.sql`, and `sql/03_gold.sql` as pipeline sources. If validation says the workspace host/profile conflicts, inspect `databricks auth profiles` and ensure the selected profile points to the host above. If it says serverless is unsupported, see Troubleshooting.

## 7. Run and monitor pipeline

```bash
databricks bundle run dlt_orders_pipeline -t dev
```

In the workspace, select **Jobs & Pipelines** and locate the deployed pipeline (development-mode deployment may prefix its display name). Inspect the most recent **update**, including event log and expectation metrics. Wait for a **successful** update before querying tables. Source graph:

```
/Volumes/.../orders/  → orders_bronze → orders_silver → daily_sales_gold
                          STREAMING        STREAMING      MATERIALIZED VIEW
```

**Do not** run `00_setup.sql` or `04_validate.sql` as pipeline source code.

## 8. Validate first-run results (only orders_001.csv)

In SQL Editor, run:

```sql
SELECT COUNT(*) AS bronze_count FROM main.dlt_orders_demo.orders_bronze;
SELECT COUNT(*) AS silver_count FROM main.dlt_orders_demo.orders_silver;
SELECT * FROM main.dlt_orders_demo.daily_sales_gold ORDER BY order_date, country;
SELECT order_id, customer_id, amount
FROM main.dlt_orders_demo.orders_silver
ORDER BY TRY_CAST(order_id AS INT);
```

Expected **Bronze = 8** and **Silver = 5**. The retained IDs are **101, 103, 104, 106, 108**. Expected Gold:

| Date | Country | Orders | Total sales |
|---|---|---:|---:|
| 2026-10-28 | USA | 2 | 750 |
| 2026-10-29 | India | 1 | 300 |
| 2026-10-29 | USA | 2 | 275 |

## 9. Verify incremental ingestion

Upload `data/orders_002.csv` into the *same* `orders` folder, using the original distinct file name.

Then perform a **normal, incremental update**, **not Full Refresh**:

```bash
databricks bundle run dlt_orders_pipeline -t dev
```

Repeat step 8 SQL queries. Expected **Bronze = 12**, **Silver = 8**, and Gold now contains five groups:

| Date | Country | Orders | Total sales |
|---|---|---:|---:|
| 2026-10-28 | USA | 2 | 750 |
| 2026-10-29 | India | 1 | 300 |
| 2026-10-29 | USA | 2 | 275 |
| 2026-10-30 | India | 1 | 200 |
| 2026-10-30 | USA | 2 | 575 |

Totals: **8 valid Silver orders, $2,100 Gold sales**. Auto Loader tracks processed filenames for incremental ingestion. It does **not** deduplicate different files containing the same order IDs.

## 10. Add evidence to your GitHub repo

Save workspace screenshots (with private information cropped) in `docs/screenshots/`, for example:

- `01-pipeline-graph.png`
- `02-successful-update.png`
- `03-expectations.png`
- `04-bronze-silver-counts.png`
- `05-gold-results.png`

You can reference images in `README.md` using relative paths, for example:

```markdown
![Medallion pipeline](docs/screenshots/01-pipeline-graph.png)
```

## 11. Publish to GitHub (safest workflow)

**Recommended:** start by cloning your **actual existing GitHub repository**, so you don't overwrite remote history. Replace `YOUR_GITHUB_USERNAME` and `YOUR_REPOSITORY_NAME` below with the repository you want to update:

```bash
cd ~/Downloads
git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY_NAME.git
cd YOUR_REPOSITORY_NAME
```

Copy the **contents** of the extracted `databricks-dlt-medallion-demo-main/` folder into the cloned repository directory (merge folders; do not copy its parent ZIP). On Mac, a simple command is:

```bash
cp -R ~/Downloads/databricks-dlt-medallion-demo-main/. ./
```

Then:

```bash
git status
git add README.md databricks.yml resources/ sql/ data/ docs/ .gitignore
git commit -m "Configure Databricks workspace and add implementation guide"
git pull --rebase origin main
git push origin main
```

If no files changed, `git commit` will report nothing to commit. If your remote uses a branch other than `main`, replace `main` with the correct branch. If the repository does **not** yet exist, create it on GitHub first and then clone it. Do not force-push to solve merge conflicts without reviewing them. Avoid copying a `.git/` directory from any other project.

**Alternative GitHub web upload:** open your repository → **Add file → Upload files** → drag the **contents of the extracted project** (not the ZIP) → commit the changes. Using Git is more reliable when replacing many files and retaining folder structure.

## Troubleshooting

| Symptom | Check |
|---|---|
| `main` catalog missing or permissions error | Verify the catalog and create schema/volume permissions; update every hard-coded `main` reference if using another catalog |
| CLI auth fails | Use host `https://dbc-431999de-fcdd.cloud.databricks.com` without `?o=...`, run `databricks auth profiles`, reauthenticate if needed |
| Bundle validation fails | Ensure you're inside the project root, have a current CLI, and check the full error text |
| Pipeline serverless unavailable | Workspace edition/permissions may not support it. Create an equivalent supported pipeline via UI and add the three SQL files; pipeline compute must be compatible |
| Bronze = 0 | Check input CSV upload folder and pipeline run result |
| Unexpected counts | Ensure batch 2 was not uploaded early; inspect data quality expectations and whether pipeline already had checkpoints |
| Duplicate order IDs | File-level discovery is not row-level CDC/deduplication |
| Push rejected | `git pull --rebase origin main`, resolve any conflicts carefully, and retry without force-push |

## Notes

- The workspace URL is safe to keep in repo documentation; credentials are **not**.
- This guide is tailored to the provided ZIP; the workspace pipeline has **not** been executed or verified remotely.
- Reference: https://docs.databricks.com/aws/en/dev-tools/cli/authentication
- Reference: https://docs.databricks.com/aws/en/dev-tools/bundles/resources
