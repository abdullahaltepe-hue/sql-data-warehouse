-- Inventory Turnover & Optimization Analysis
-- Identifies slow-moving stock, excess inventory, and reorder points

WITH inventory_metrics AS (
    SELECT
        p.material_id,
        p.material_type_desc,
        p.product_category,
        p.weight_category,
        fi.plant,
        fi.storage_location,
        fi.quantity_on_hand,
        fi.quantity_reserved,
        fi.quantity_available,
        fi.stock_value,
        fi.last_movement_date,
        CURRENT_DATE - fi.last_movement_date AS days_since_movement
    FROM {{ ref('fct_inventory') }} fi
    JOIN {{ ref('dim_product') }} p ON fi.product_key = p.product_key
    WHERE fi.snapshot_date = CURRENT_DATE
),

sales_velocity AS (
    SELECT
        f.product_key,
        p.material_id,
        COUNT(DISTINCT d.year_month) AS active_months,
        SUM(f.order_quantity) AS total_qty_sold_12m,
        AVG(f.order_quantity) AS avg_monthly_qty,
        STDDEV(f.order_quantity) AS stddev_monthly_qty
    FROM {{ ref('fct_sales') }} f
    JOIN {{ ref('dim_date') }} d ON f.date_key = d.date_key
    JOIN {{ ref('dim_product') }} p ON f.product_key = p.product_key
    WHERE d.calendar_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 1, 2
),

final AS (
    SELECT
        im.material_id,
        im.material_type_desc,
        im.product_category,
        im.plant,
        im.quantity_on_hand,
        im.stock_value,
        im.days_since_movement,

        COALESCE(sv.avg_monthly_qty, 0) AS avg_monthly_demand,
        COALESCE(sv.stddev_monthly_qty, 0) AS demand_variability,

        -- Inventory Turnover
        CASE
            WHEN im.quantity_on_hand > 0 AND sv.total_qty_sold_12m > 0
            THEN ROUND(sv.total_qty_sold_12m::DECIMAL / im.quantity_on_hand, 2)
            ELSE 0
        END AS inventory_turnover,

        -- Days of Supply
        CASE
            WHEN sv.avg_monthly_qty > 0
            THEN ROUND(im.quantity_on_hand / (sv.avg_monthly_qty / 30), 0)
            ELSE 999
        END AS days_of_supply,

        -- Safety Stock (using Z=1.65 for 95% service level)
        CASE
            WHEN sv.stddev_monthly_qty > 0
            THEN ROUND(1.65 * sv.stddev_monthly_qty * SQRT(2), 0)  -- 2 week lead time
            ELSE 0
        END AS safety_stock,

        -- Reorder Point
        CASE
            WHEN sv.avg_monthly_qty > 0
            THEN ROUND(sv.avg_monthly_qty / 2 + 1.65 * sv.stddev_monthly_qty * SQRT(2), 0)
            ELSE 0
        END AS reorder_point,

        -- Stock Classification
        CASE
            WHEN im.days_since_movement > 365 THEN 'Dead Stock'
            WHEN im.days_since_movement > 180 THEN 'Slow Moving'
            WHEN im.days_since_movement > 90 THEN 'Moderate'
            ELSE 'Fast Moving'
        END AS stock_movement_class,

        -- ABC Classification by value
        PERCENT_RANK() OVER (ORDER BY im.stock_value DESC) AS value_percentile,
        CASE
            WHEN PERCENT_RANK() OVER (ORDER BY im.stock_value DESC) <= 0.20 THEN 'A'
            WHEN PERCENT_RANK() OVER (ORDER BY im.stock_value DESC) <= 0.50 THEN 'B'
            ELSE 'C'
        END AS abc_class

    FROM inventory_metrics im
    LEFT JOIN sales_velocity sv ON im.material_id = sv.material_id
)

SELECT
    *,
    CASE
        WHEN stock_movement_class = 'Dead Stock' THEN 'Write-off candidate'
        WHEN days_of_supply > 180 THEN 'Excess - reduce orders'
        WHEN quantity_on_hand <= reorder_point THEN 'Below ROP - reorder'
        WHEN quantity_on_hand <= safety_stock THEN 'Critical - expedite'
        ELSE 'Healthy'
    END AS action_recommendation
FROM final
ORDER BY stock_value DESC;
