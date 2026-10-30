{{ config(
    materialized='view',
    schema='staging'
) }}

WITH source AS (
    SELECT *
    FROM {{ source('auctionet_raw', 'raw_auctionet_categories') }}
),

top_level AS (
    SELECT
        category.value:id::STRING AS category_id,
        category.value:name::STRING AS category_name,
        category.value:parent_id::STRING AS parent_category_id,
        NULL::STRING AS parent_category_name,
        category.value:children AS children,
        file_path,
        ingested_at
    FROM source,
    LATERAL FLATTEN(input => json_data:categories) category
),

child_categories AS (
    SELECT
        child.value:id::STRING AS category_id,
        child.value:name::STRING AS category_name,
        child.value:parent_id::STRING AS parent_category_id,
        parent.category_name AS parent_category_name,
        child.value:children AS children,
        parent.file_path,
        parent.ingested_at
    FROM top_level parent,
    LATERAL FLATTEN(input => parent.children) child
),

combined AS (
    SELECT
        category_id,
        category_name,
        parent_category_id,
        parent_category_name,
        file_path,
        ingested_at
    FROM top_level

    UNION ALL

    SELECT
        category_id,
        category_name,
        parent_category_id,
        parent_category_name,
        file_path,
        ingested_at
    FROM child_categories
)

SELECT *
FROM combined