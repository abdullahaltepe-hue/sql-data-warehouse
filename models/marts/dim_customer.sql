-- Dimension: Customer Master (SCD Type 2)
-- Tracks historical changes to customer attributes

WITH source AS (
    SELECT * FROM {{ ref('stg_sap_customers') }}
),

customer_history AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY created_date
        ) AS version_number
    FROM source
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'version_number']) }} AS customer_key,
        customer_id,
        customer_name,
        customer_name_2,
        country_code,
        region_code,
        city,
        postal_code,
        street,
        account_group,
        industry_code,
        language_key,

        -- SCD Type 2 fields
        created_date AS valid_from,
        COALESCE(
            LEAD(created_date) OVER (PARTITION BY customer_id ORDER BY created_date) - INTERVAL '1 day',
            '9999-12-31'::DATE
        ) AS valid_to,
        CASE
            WHEN LEAD(created_date) OVER (PARTITION BY customer_id ORDER BY created_date) IS NULL
            THEN TRUE
            ELSE FALSE
        END AS is_current,

        -- Customer segmentation
        CASE account_group
            WHEN '0001' THEN 'Domestic'
            WHEN '0002' THEN 'International'
            WHEN '0003' THEN 'Intercompany'
            WHEN '0004' THEN 'One-Time'
            ELSE 'Other'
        END AS customer_segment,

        -- Geography enrichment
        CASE country_code
            WHEN 'DE' THEN 'EMEA'
            WHEN 'GB' THEN 'EMEA'
            WHEN 'FR' THEN 'EMEA'
            WHEN 'TR' THEN 'EMEA'
            WHEN 'US' THEN 'Americas'
            WHEN 'CA' THEN 'Americas'
            WHEN 'BR' THEN 'Americas'
            WHEN 'CN' THEN 'APAC'
            WHEN 'JP' THEN 'APAC'
            WHEN 'AU' THEN 'APAC'
            ELSE 'Other'
        END AS sales_region,

        _loaded_at

    FROM customer_history
)

SELECT * FROM final
