-- Custom data test: All sales should have non-negative net value
-- Excludes credit memos which are filtered at staging

SELECT
    sales_key,
    sales_order_id,
    net_value
FROM {{ ref('fct_sales') }}
WHERE net_value < 0
