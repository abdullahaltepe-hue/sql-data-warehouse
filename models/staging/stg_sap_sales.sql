-- Staging model for SAP Sales Documents (VBAK/VBAP)
-- Source: SAP SD Module

WITH header AS (
    SELECT * FROM {{ source('sap', 'vbak') }}
),

items AS (
    SELECT * FROM {{ source('sap', 'vbap') }}
),

joined AS (
    SELECT
        CAST(h.vbeln AS VARCHAR(10)) AS sales_order_id,
        CAST(i.posnr AS VARCHAR(6)) AS line_item,
        CAST(h.auart AS VARCHAR(4)) AS order_type,
        CAST(h.vkorg AS VARCHAR(4)) AS sales_org,
        CAST(h.vtweg AS VARCHAR(2)) AS distribution_channel,
        CAST(h.spart AS VARCHAR(2)) AS division,
        CAST(h.kunnr AS VARCHAR(10)) AS customer_id,
        CAST(i.matnr AS VARCHAR(18)) AS material_id,
        CAST(h.erdat AS DATE) AS order_date,
        CAST(h.audat AS DATE) AS document_date,
        CAST(i.kwmeng AS DECIMAL(15,3)) AS order_quantity,
        CAST(i.vrkme AS VARCHAR(3)) AS sales_unit,
        CAST(i.netwr AS DECIMAL(15,2)) AS net_value,
        CAST(i.waerk AS VARCHAR(5)) AS currency,
        CAST(i.werks AS VARCHAR(4)) AS plant,
        CAST(i.lgort AS VARCHAR(4)) AS storage_location,
        CASE h.gbstk
            WHEN 'C' THEN 'completed'
            WHEN 'B' THEN 'partially_processed'
            WHEN 'A' THEN 'not_processed'
            ELSE 'unknown'
        END AS processing_status,
        CURRENT_TIMESTAMP AS _loaded_at
    FROM header h
    INNER JOIN items i ON h.vbeln = i.vbeln
    WHERE h.auart NOT IN ('ZRE', 'ZCR')  -- Exclude returns and credits
)

SELECT * FROM joined
