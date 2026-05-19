-- Staging model for SAP Material Master (MARA/MAKT)
-- Source: SAP ECC/S4HANA

WITH source AS (
    SELECT * FROM {{ source('sap', 'mara') }}
),

renamed AS (
    SELECT
        CAST(matnr AS VARCHAR(18)) AS material_id,
        CAST(mtart AS VARCHAR(4)) AS material_type,
        CAST(mbrsh AS VARCHAR(1)) AS industry_sector,
        CAST(matkl AS VARCHAR(9)) AS material_group,
        CAST(meins AS VARCHAR(3)) AS base_unit_of_measure,
        CAST(bstme AS VARCHAR(3)) AS order_unit,
        CAST(gewei AS VARCHAR(3)) AS weight_unit,
        CAST(ntgew AS DECIMAL(13,3)) AS net_weight,
        CAST(brgew AS DECIMAL(13,3)) AS gross_weight,
        CAST(spart AS VARCHAR(2)) AS division,
        CAST(prdha AS VARCHAR(18)) AS product_hierarchy,
        CAST(ersda AS DATE) AS created_date,
        CAST(laeda AS DATE) AS last_changed_date,
        CAST(lvorm AS BOOLEAN) AS is_flagged_for_deletion,
        CURRENT_TIMESTAMP AS _loaded_at
    FROM source
)

SELECT * FROM renamed
WHERE NOT is_flagged_for_deletion
