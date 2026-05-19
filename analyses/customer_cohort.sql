-- Customer Cohort Retention Analysis
-- Tracks customer purchase behavior by acquisition cohort

WITH first_purchase AS (
    SELECT
        f.customer_key,
        MIN(d.year_month) AS cohort_month,
        MIN(d.calendar_date) AS first_purchase_date
    FROM {{ ref('fct_sales') }} f
    JOIN {{ ref('dim_date') }} d ON f.date_key = d.date_key
    GROUP BY 1
),

monthly_activity AS (
    SELECT DISTINCT
        f.customer_key,
        d.year_month AS activity_month
    FROM {{ ref('fct_sales') }} f
    JOIN {{ ref('dim_date') }} d ON f.date_key = d.date_key
),

cohort_data AS (
    SELECT
        fp.cohort_month,
        ma.activity_month,
        (EXTRACT(YEAR FROM TO_DATE(ma.activity_month, 'YYYY-MM')) -
         EXTRACT(YEAR FROM TO_DATE(fp.cohort_month, 'YYYY-MM'))) * 12 +
        (EXTRACT(MONTH FROM TO_DATE(ma.activity_month, 'YYYY-MM')) -
         EXTRACT(MONTH FROM TO_DATE(fp.cohort_month, 'YYYY-MM'))) AS months_since_first,
        COUNT(DISTINCT ma.customer_key) AS active_customers
    FROM first_purchase fp
    JOIN monthly_activity ma ON fp.customer_key = ma.customer_key
    GROUP BY 1, 2, 3
),

cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_key) AS cohort_size
    FROM first_purchase
    GROUP BY 1
),

retention AS (
    SELECT
        cd.cohort_month,
        cd.months_since_first,
        cs.cohort_size,
        cd.active_customers,
        ROUND(cd.active_customers::DECIMAL / cs.cohort_size * 100, 2) AS retention_rate
    FROM cohort_data cd
    JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
    WHERE cd.months_since_first >= 0
)

SELECT
    cohort_month,
    cohort_size,
    months_since_first,
    active_customers,
    retention_rate,
    AVG(retention_rate) OVER (
        PARTITION BY months_since_first
        ORDER BY cohort_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_retention
FROM retention
ORDER BY cohort_month, months_since_first;
