-- Dimension: Product/Material Master
-- Contains product hierarchy and attributes

WITH source AS (
    SELECT * FROM {{ ref('stg_sap_materials') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['material_id']) }} AS product_key,
        material_id,
        material_type,
        industry_sector,
        material_group,
        base_unit_of_measure,
        order_unit,
        weight_unit,
        net_weight,
        gross_weight,
        division,
        product_hierarchy,

        -- Product type description
        CASE material_type
            WHEN 'FERT' THEN 'Finished Good'
            WHEN 'HALB' THEN 'Semi-Finished'
            WHEN 'ROH'  THEN 'Raw Material'
            WHEN 'HIBE' THEN 'Operating Supply'
            WHEN 'DIEN' THEN 'Service'
            WHEN 'NLAG' THEN 'Non-Stock'
            ELSE 'Other'
        END AS material_type_desc,

        -- Hierarchy levels (from product_hierarchy field)
        LEFT(product_hierarchy, 5) AS product_category,
        LEFT(product_hierarchy, 10) AS product_subcategory,
        product_hierarchy AS product_line,

        -- Weight category
        CASE
            WHEN net_weight IS NULL THEN 'Unknown'
            WHEN net_weight <= 1 THEN 'Light'
            WHEN net_weight <= 10 THEN 'Medium'
            WHEN net_weight <= 100 THEN 'Heavy'
            ELSE 'Very Heavy'
        END AS weight_category,

        created_date,
        last_changed_date,
        CURRENT_DATE - created_date AS days_since_creation,
        _loaded_at

    FROM source
)

SELECT * FROM final
