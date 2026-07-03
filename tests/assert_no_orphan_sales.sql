-- Custom data test: Ensure no sales records reference non-existent customers
-- Returns rows that violate the constraint (test passes if 0 rows)

SELECT
    f.sales_key,
    f.sales_order_id,
    f.customer_key
FROM {{ ref('fct_sales') }} f
LEFT JOIN {{ ref('dim_customer') }} c ON f.customer_key = c.customer_key
WHERE f.customer_key IS NOT NULL
  AND c.customer_key IS NULL
