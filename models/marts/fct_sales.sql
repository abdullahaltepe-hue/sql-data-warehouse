-- Fact table: Sales transactions at line item grain
-- Grain: One row per sales order line item

WITH sales AS (
    SELECT * FROM {{ ref('stg_sap_sales') }}
),

customers AS (
    SELECT * FROM {{ ref('dim_customer') }}
),

products AS (
    SELECT * FROM {{ ref('dim_product') }}
),

dates AS (
    SELECT * FROM {{ ref('dim_date') }}
),

final AS (
    SELECT
        -- Surrogate keys
        {{ dbt_utils.generate_surrogate_key(['s.sales_order_id', 's.line_item']) }} AS sales_key,

        -- Dimension foreign keys
        c.customer_key,
        p.product_key,
        d.date_key,

        -- Degenerate dimensions
        s.sales_order_id,
        s.line_item,
        s.order_type,
        s.sales_org,
        s.distribution_channel,
        s.division,
        s.plant,
        s.storage_location,
        s.processing_status,

        -- Measures
        s.order_quantity,
        s.net_value,
        s.net_value / NULLIF(s.order_quantity, 0) AS unit_price,
        s.currency,

        -- Calculated measures
        CASE
            WHEN s.processing_status = 'completed' THEN s.net_value
            ELSE 0
        END AS fulfilled_value,

        CASE
            WHEN s.processing_status IN ('not_processed', 'partially_processed')
            THEN s.net_value
            ELSE 0
        END AS open_order_value,

        -- Metadata
        s._loaded_at

    FROM sales s
    LEFT JOIN customers c ON s.customer_id = c.customer_id
    LEFT JOIN products p ON s.material_id = p.material_id
    LEFT JOIN dates d ON s.order_date = d.calendar_date
)

SELECT * FROM final
