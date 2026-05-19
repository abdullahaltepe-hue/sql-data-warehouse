-- Staging model for SAP Customer Master (KNA1/KNB1)
-- Source: SAP ECC/S4HANA

WITH source AS (
    SELECT * FROM {{ source('sap', 'kna1') }}
),

renamed AS (
    SELECT
        CAST(kunnr AS VARCHAR(10)) AS customer_id,
        CAST(name1 AS VARCHAR(100)) AS customer_name,
        CAST(name2 AS VARCHAR(100)) AS customer_name_2,
        CAST(land1 AS VARCHAR(3)) AS country_code,
        CAST(regio AS VARCHAR(3)) AS region_code,
        CAST(ort01 AS VARCHAR(35)) AS city,
        CAST(pstlz AS VARCHAR(10)) AS postal_code,
        CAST(stras AS VARCHAR(60)) AS street,
        CAST(ktokd AS VARCHAR(4)) AS account_group,
        CAST(brsch AS VARCHAR(4)) AS industry_code,
        CAST(spras AS VARCHAR(2)) AS language_key,
        CAST(erdat AS DATE) AS created_date,
        CAST(loevm AS BOOLEAN) AS is_blocked,
        CURRENT_TIMESTAMP AS _loaded_at
    FROM source
)

SELECT * FROM renamed
WHERE NOT is_blocked
