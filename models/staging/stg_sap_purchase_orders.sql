-- Staging model for SAP Purchase Orders (EKKO/EKPO)
-- Source: SAP MM Module

WITH header AS (
    SELECT * FROM {{ source('sap', 'ekko') }}
),

items AS (
    SELECT * FROM {{ source('sap', 'ekpo') }}
),

joined AS (
    SELECT
        CAST(h.ebeln AS VARCHAR(10)) AS po_number,
        CAST(i.ebelp AS VARCHAR(5)) AS po_item,
        CAST(h.bsart AS VARCHAR(4)) AS document_type,
        CAST(h.ekorg AS VARCHAR(4)) AS purchasing_org,
        CAST(h.ekgrp AS VARCHAR(3)) AS purchasing_group,
        CAST(h.lifnr AS VARCHAR(10)) AS vendor_id,
        CAST(i.matnr AS VARCHAR(18)) AS material_id,
        CAST(h.bedat AS DATE) AS order_date,
        CAST(i.eindt AS DATE) AS delivery_date,
        CAST(i.menge AS DECIMAL(13,3)) AS order_quantity,
        CAST(i.meins AS VARCHAR(3)) AS unit_of_measure,
        CAST(i.netpr AS DECIMAL(13,2)) AS net_price,
        CAST(i.netwr AS DECIMAL(13,2)) AS net_value,
        CAST(i.waers AS VARCHAR(5)) AS currency,
        CAST(i.werks AS VARCHAR(4)) AS plant,
        CAST(i.lgort AS VARCHAR(4)) AS storage_location,
        CASE h.statu
            WHEN '5' THEN 'released'
            WHEN '9' THEN 'completed'
            WHEN '1' THEN 'created'
            ELSE 'other'
        END AS po_status,
        CURRENT_TIMESTAMP AS _loaded_at
    FROM header h
    INNER JOIN items i ON h.ebeln = i.ebeln
    WHERE h.loekz IS NULL OR h.loekz = ''
)

SELECT * FROM joined
