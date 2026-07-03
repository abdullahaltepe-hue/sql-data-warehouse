-- Dimension: Vendor/Supplier Master
-- Contains vendor attributes and regional classification

WITH source AS (
    SELECT * FROM {{ ref('stg_sap_vendors') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['vendor_id']) }} AS vendor_key,
        vendor_id,
        vendor_name,
        vendor_name_2,
        country_code,
        region_code,
        city,
        postal_code,
        account_group,
        industry_code,

        CASE account_group
            WHEN '0001' THEN 'Domestic Vendor'
            WHEN '0002' THEN 'International Vendor'
            WHEN '0003' THEN 'Intercompany'
            WHEN '0004' THEN 'One-Time Vendor'
            ELSE 'Other'
        END AS vendor_segment,

        CASE country_code
            WHEN 'DE' THEN 'EMEA'
            WHEN 'GB' THEN 'EMEA'
            WHEN 'FR' THEN 'EMEA'
            WHEN 'TR' THEN 'EMEA'
            WHEN 'US' THEN 'Americas'
            WHEN 'CA' THEN 'Americas'
            WHEN 'MX' THEN 'Americas'
            WHEN 'CN' THEN 'APAC'
            WHEN 'JP' THEN 'APAC'
            WHEN 'IN' THEN 'APAC'
            ELSE 'Other'
        END AS sourcing_region,

        created_date,
        _loaded_at

    FROM source
)

SELECT * FROM final
