# Enterprise Data Warehouse - Star Schema Design

A production-grade data warehouse implementation using dimensional modeling (Kimball methodology). Features a complete star schema design for retail/manufacturing analytics with dbt transformations, complex analytical queries, and data quality tests.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  SAP ERP    │     │  CRM System │     │  External   │
│  (Source)   │     │  (Source)   │     │  APIs       │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Staging   │  (Raw extracts)
                    │    Layer    │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ Intermediate│  (Business logic)
                    │    Layer    │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │    Marts    │  (Star schemas)
                    │    Layer    │
                    └─────────────┘
```

## Star Schema Design

### Fact Tables
- `fct_sales` - Sales transactions at line item grain
- `fct_inventory` - Daily inventory snapshots
- `fct_purchase_orders` - Procurement transactions
- `fct_budget` - Budget allocations by period

### Dimension Tables
- `dim_customer` - Customer master (SCD Type 2)
- `dim_product` - Material/product hierarchy
- `dim_date` - Date dimension with fiscal calendar
- `dim_vendor` - Supplier master
- `dim_cost_center` - Organizational hierarchy
- `dim_geography` - Location hierarchy

## Tech Stack

| Tool | Purpose |
|------|---------|
| dbt Core | Transformation orchestration |
| PostgreSQL / Snowflake | Target warehouse |
| SQL | Modeling & analytics |
| Python | Data quality checks |
| GitHub Actions | CI/CD for dbt |

## Project Structure

```
├── models/
│   ├── staging/          # 1:1 source mirrors with type casting
│   │   ├── stg_sap_materials.sql
│   │   ├── stg_sap_customers.sql
│   │   ├── stg_sap_sales.sql
│   │   └── stg_sap_vendors.sql
│   ├── intermediate/     # Business logic & joins
│   │   ├── int_sales_enriched.sql
│   │   └── int_inventory_daily.sql
│   └── marts/            # Final star schema
│       ├── fct_sales.sql
│       ├── fct_inventory.sql
│       ├── dim_customer.sql
│       ├── dim_product.sql
│       └── dim_date.sql
├── analyses/             # Ad-hoc analytical queries
├── seeds/                # Static reference data
├── macros/               # Reusable SQL macros
├── tests/                # Data quality tests
└── dbt_project.yml
```

## Key Analytical Queries

The `analyses/` folder contains production-grade analytical queries:
- Revenue trend analysis with YoY comparison
- Customer cohort retention
- Inventory turnover optimization
- Pareto analysis (80/20 rule)
- Moving averages & running totals

## Data Quality

Automated tests cover:
- Referential integrity between facts and dimensions
- Not-null constraints on key fields
- Uniqueness of surrogate keys
- Accepted value ranges
- Row count anomaly detection

## Getting Started

```bash
pip install dbt-postgres
dbt deps
dbt seed
dbt run
dbt test
```

## License

MIT
