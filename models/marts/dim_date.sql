-- Dimension: Date/Calendar with fiscal periods
-- Generates a complete date spine with business calendar attributes

WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2026-12-31' as date)"
    ) }}
),

final AS (
    SELECT
        CAST(date_day AS DATE) AS calendar_date,
        {{ dbt_utils.generate_surrogate_key(['date_day']) }} AS date_key,

        -- Calendar attributes
        EXTRACT(YEAR FROM date_day) AS calendar_year,
        EXTRACT(QUARTER FROM date_day) AS calendar_quarter,
        EXTRACT(MONTH FROM date_day) AS calendar_month,
        EXTRACT(WEEK FROM date_day) AS calendar_week,
        EXTRACT(DOY FROM date_day) AS day_of_year,
        EXTRACT(DOW FROM date_day) AS day_of_week,
        TO_CHAR(date_day, 'YYYY-MM') AS year_month,
        TO_CHAR(date_day, 'Month') AS month_name,
        TO_CHAR(date_day, 'Day') AS day_name,

        -- Fiscal calendar (Oct start)
        CASE
            WHEN EXTRACT(MONTH FROM date_day) >= 10
            THEN EXTRACT(YEAR FROM date_day) + 1
            ELSE EXTRACT(YEAR FROM date_day)
        END AS fiscal_year,

        CASE
            WHEN EXTRACT(MONTH FROM date_day) >= 10
            THEN EXTRACT(MONTH FROM date_day) - 9
            ELSE EXTRACT(MONTH FROM date_day) + 3
        END AS fiscal_month,

        CASE
            WHEN EXTRACT(MONTH FROM date_day) BETWEEN 10 AND 12 THEN 1
            WHEN EXTRACT(MONTH FROM date_day) BETWEEN 1 AND 3 THEN 2
            WHEN EXTRACT(MONTH FROM date_day) BETWEEN 4 AND 6 THEN 3
            ELSE 4
        END AS fiscal_quarter,

        -- Business day flags
        CASE
            WHEN EXTRACT(DOW FROM date_day) IN (0, 6) THEN FALSE
            ELSE TRUE
        END AS is_business_day,

        -- Period indicators
        CASE
            WHEN date_day = DATE_TRUNC('month', date_day) THEN TRUE
            ELSE FALSE
        END AS is_month_start,

        CASE
            WHEN date_day = (DATE_TRUNC('month', date_day) + INTERVAL '1 month' - INTERVAL '1 day')::DATE
            THEN TRUE
            ELSE FALSE
        END AS is_month_end,

        -- Relative date flags
        CASE WHEN date_day = CURRENT_DATE THEN TRUE ELSE FALSE END AS is_today,
        CURRENT_DATE - date_day::DATE AS days_ago

    FROM date_spine
)

SELECT * FROM final
