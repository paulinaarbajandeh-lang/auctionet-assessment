{{ config(
    materialized='table',
    schema='marts'
) }}

WITH categories AS (
    SELECT *
    FROM {{ ref('stg_auctionet_categories') }}
)

SELECT
    category_id,
    category_name,
    parent_category_id,
    parent_category_name
FROM categories