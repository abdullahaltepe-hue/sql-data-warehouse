-- Fact table: Purchase Order transactions at line item grain
-- Grain: One row per PO line item

WITH purchases AS (
    SELECT * FROM {{ ref('stg_sap_purchase_orders') }}
),

vendors AS (
    SELECT * FROM {{ ref('dim_vendor') }}
),

products AS (
    SELECT * FROM {{ ref('dim_product') }}
),

dates AS (
    SELECT * FROM {{ ref('dim_date') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['po.po_number', 'po.po_item']) }} AS purchase_key,

        -- Dimension keys
        v.vendor_key,
        p.product_key,
        d.date_key AS order_date_key,

        -- Degenerate dimensions
        po.po_number,
        po.po_item,
        po.document_type,
        po.purchasing_org,
        po.purchasing_group,
        po.plant,
        po.storage_location,
        po.po_status,

        -- Measures
        po.order_quantity,
        po.net_price,
        po.net_value,
        po.currency,

        -- Delivery metrics
        po.delivery_date,
        po.order_date,
        po.delivery_date - po.order_date AS planned_lead_time_days,

        -- Metadata
        po._loaded_at

    FROM purchases po
    LEFT JOIN vendors v ON po.vendor_id = v.vendor_id
    LEFT JOIN products p ON po.material_id = p.material_id
    LEFT JOIN dates d ON po.order_date = d.calendar_date
)

SELECT * FROM final
