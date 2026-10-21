{{ config(
    materialized='table',
    schema='marts'
) }}

WITH cleaned_items AS (
    SELECT *
    FROM {{ ref('int_auctionet_items_cleaned') }}
),

ranked_houses AS (
    SELECT
        company_id,
        house_name,
        location,
        ROW_NUMBER() OVER (
            PARTITION BY company_id
            ORDER BY ingested_at DESC
        ) AS row_num
    FROM cleaned_items
    WHERE company_id IS NOT NULL
),

houses AS (
    SELECT
        company_id,
        house_name,
        location
    FROM ranked_houses
    WHERE row_num = 1
)

SELECT
    h.company_id,
    h.house_name,
    h.location,
    m.country
FROM houses h
LEFT JOIN {{ ref('location_country_map') }} m
    ON h.location = m.location