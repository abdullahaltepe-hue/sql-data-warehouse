-- Revenue Trend Analysis with YoY Comparison & Moving Averages
-- Provides executive-level revenue insights

WITH monthly_revenue AS (
    SELECT
        d.calendar_year,
        d.calendar_month,
        d.year_month,
        d.fiscal_year,
        d.fiscal_quarter,
        c.sales_region,
        c.customer_segment,
        p.material_type_desc AS product_type,
        COUNT(DISTINCT f.sales_order_id) AS order_count,
        COUNT(DISTINCT f.customer_key) AS active_customers,
        SUM(f.net_value) AS gross_revenue,
        SUM(f.fulfilled_value) AS fulfilled_revenue,
        SUM(f.open_order_value) AS backlog_value,
        AVG(f.unit_price) AS avg_unit_price,
        SUM(f.order_quantity) AS total_quantity
    FROM {{ ref('fct_sales') }} f
    JOIN {{ ref('dim_date') }} d ON f.date_key = d.date_key
    JOIN {{ ref('dim_customer') }} c ON f.customer_key = c.customer_key
    JOIN {{ ref('dim_product') }} p ON f.product_key = p.product_key
    WHERE c.is_current = TRUE
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

with_yoy AS (
    SELECT
        *,
        LAG(gross_revenue, 12) OVER (
            PARTITION BY sales_region, customer_segment, product_type
            ORDER BY calendar_year, calendar_month
        ) AS revenue_prior_year,

        ROUND(
            (gross_revenue - LAG(gross_revenue, 12) OVER (
                PARTITION BY sales_region, customer_segment, product_type
                ORDER BY calendar_year, calendar_month
            )) / NULLIF(LAG(gross_revenue, 12) OVER (
                PARTITION BY sales_region, customer_segment, product_type
                ORDER BY calendar_year, calendar_month
            ), 0) * 100, 2
        ) AS yoy_growth_pct,

        AVG(gross_revenue) OVER (
            PARTITION BY sales_region, customer_segment, product_type
            ORDER BY calendar_year, calendar_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS revenue_3m_avg,

        AVG(gross_revenue) OVER (
            PARTITION BY sales_region, customer_segment, product_type
            ORDER BY calendar_year, calendar_month
            ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ) AS revenue_12m_avg,

        SUM(gross_revenue) OVER (
            PARTITION BY sales_region, customer_segment, product_type, calendar_year
            ORDER BY calendar_month
            ROWS UNBOUNDED PRECEDING
        ) AS ytd_revenue

    FROM monthly_revenue
),

ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY calendar_year, calendar_month
            ORDER BY gross_revenue DESC
        ) AS revenue_rank,
        ROUND(
            gross_revenue / SUM(gross_revenue) OVER (
                PARTITION BY calendar_year, calendar_month
            ) * 100, 2
        ) AS revenue_share_pct
    FROM with_yoy
)

SELECT * FROM ranked
ORDER BY calendar_year DESC, calendar_month DESC, gross_revenue DESC;
