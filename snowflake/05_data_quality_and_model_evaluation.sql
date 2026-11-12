-- Data quality and model evaluation
-- Check data quality, historical coverage and model performance
-- Run queries individually. Results depend on the latest data

-- 1. FINAL DATASET: ROW COUNT AND UNIQUE ITEM IDS
-- Check that each active item appears only once

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT item_id) AS unique_items,
    COUNT(*) - COUNT(DISTINCT item_id) AS duplicate_rows
FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_MARTS.FCT_ACTIVE_ITEM_PRIORITISATION;


-- 2. HISTORICAL DATA COVERAGE
-- Check how many active items have historical data available

SELECT
    COUNT(*) AS total_active_items,

    COUNT_IF(
        category_ended_items IS NULL
        OR category_ended_items = 0
    ) AS items_without_category_history,

    COUNT_IF(
        house_ended_items IS NULL
        OR house_ended_items = 0
    ) AS items_without_house_history,

    COUNT_IF(
        (category_ended_items IS NULL OR category_ended_items = 0)
        AND
        (house_ended_items IS NULL OR house_ended_items = 0)
    ) AS items_without_any_history,

    COUNT_IF(
        category_ended_items >= 100
        AND house_ended_items >= 100
    ) AS items_with_strong_sample_coverage

FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_INTERMEDIATE.INT_ACTIVE_ITEM_PRIORITISATION;


-- 3. HISTORICAL AUCTION DATA QUALITY
-- Check for duplicate items and missing category or house IDs

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT item_id) AS unique_items,
    COUNT(*) - COUNT(DISTINCT item_id) AS duplicate_rows,
    COUNT_IF(company_id IS NULL) AS missing_company,
    COUNT_IF(main_category_id IS NULL) AS missing_main_category,
    COUNT_IF(hammer_price_sek IS NULL) AS missing_hammer_price,
    COUNT_IF(estimate_sek IS NULL) AS missing_estimate
FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG.FCT_ENDED_AUCTIONS;


-- 4. BID DATA QUALITY
-- Check unique bid IDs and the number of items with bids

SELECT
    COUNT(*) AS total_bid_rows,
    COUNT(DISTINCT bid_id) AS unique_bid_ids,
    COUNT_IF(bid_id IS NULL) AS missing_bid_ids,
    COUNT(*) - COUNT(DISTINCT bid_id)
        - COUNT_IF(bid_id IS NULL) AS duplicate_bid_rows,
    COUNT(DISTINCT item_id) AS items_with_bids
FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_MARTS.FCT_BIDS;


-- 5. CURRENCY CONVERSION
-- Compare original estimates with values converted to SEK
-- The current model uses fixed exchange rates

SELECT
    currency,
    COUNT(*) AS items,
    ROUND(AVG(estimate), 2) AS avg_estimate_original,
    ROUND(AVG(estimate_sek), 2) AS avg_estimate_sek,
    ROUND(AVG(starting_bid_amount), 2) AS avg_starting_bid_original,
    ROUND(AVG(starting_bid_amount_sek), 2) AS avg_starting_bid_sek
FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_INTERMEDIATE.INT_AUCTIONET_ITEMS_CLEANED
GROUP BY currency
ORDER BY currency;


-- 6. PRIORITISATION SCORE DISTRIBUTION
-- Review the score range and distribution across active items

SELECT
    COUNT(*) AS total_items,
    ROUND(MIN(prioritisation_score), 4) AS min_score,
    ROUND(AVG(prioritisation_score), 4) AS avg_score,
    ROUND(MEDIAN(prioritisation_score), 4) AS median_score,
    ROUND(MAX(prioritisation_score), 4) AS max_score,
    ROUND(
        PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY prioritisation_score), 4
    ) AS p25_score,
    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY prioritisation_score), 4
    ) AS p75_score,
    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY prioritisation_score), 4
    ) AS p90_score
FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_INTERMEDIATE.INT_ACTIVE_ITEM_PRIORITISATION;


-- 7. SCORE COMPONENT BREAKDOWN
-- Check how engagement and historical performance contribute to the final score for the top 10 items

WITH contributions AS (
    SELECT
        item_id,
        prioritisation_rank,
        prioritisation_score,

        engagement_score * 0.50 AS engagement_contribution,

        category_performance_score
            * category_confidence * 0.25 AS category_contribution,

        house_performance_score
            * house_confidence * 0.25 AS house_contribution

    FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_INTERMEDIATE.INT_ACTIVE_ITEM_PRIORITISATION
)

SELECT
    item_id,
    prioritisation_rank,
    ROUND(prioritisation_score, 4) AS priority_score,
    ROUND(engagement_contribution, 4) AS engagement_contribution,
    ROUND(category_contribution, 4) AS category_contribution,
    ROUND(house_contribution, 4) AS house_contribution,

    ROUND(
        engagement_contribution
        + category_contribution
        + house_contribution
        - prioritisation_score, 6
    ) AS score_difference

FROM contributions
ORDER BY prioritisation_rank, item_id
LIMIT 10;


-- 8. TOP 100 RANKING COMPARISON
-- Compare the model's top 100 with a ranking based on bid count
-- Use item_id to break ties consistently

WITH ranked AS (
    SELECT
        item_id,
        current_bid_count,
        category_pct_above_estimate,
        house_pct_above_estimate,

        ROW_NUMBER() OVER (
            ORDER BY prioritisation_score DESC, item_id
        ) AS model_rank,

        ROW_NUMBER() OVER (
            ORDER BY current_bid_count DESC, item_id
        ) AS bid_count_rank

    FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_MARTS.FCT_ACTIVE_ITEM_PRIORITISATION
)

SELECT
    CASE
        WHEN model_rank <= 100 AND bid_count_rank <= 100
            THEN 'Both top 100'
        WHEN model_rank <= 100
            THEN 'Model only'
        WHEN bid_count_rank <= 100
            THEN 'Bid count only'
    END AS ranking_group,

    COUNT(*) AS items,
    ROUND(AVG(current_bid_count), 2) AS avg_bids,
    ROUND(AVG(category_pct_above_estimate) * 100, 1)
        AS avg_category_above_estimate_pct,
    ROUND(AVG(house_pct_above_estimate) * 100, 1)
        AS avg_house_above_estimate_pct

FROM ranked
WHERE model_rank <= 100
   OR bid_count_rank <= 100
GROUP BY 1
ORDER BY 1;


-- 9. TOP 100 OVERLAP
-- Count items shared by both rankings and unique to each

WITH ranked AS (
    SELECT
        item_id,

        ROW_NUMBER() OVER (
            ORDER BY prioritisation_score DESC, item_id
        ) AS model_rank,

        ROW_NUMBER() OVER (
            ORDER BY current_bid_count DESC, item_id
        ) AS bid_count_rank

    FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_MARTS.FCT_ACTIVE_ITEM_PRIORITISATION
)

SELECT
    COUNT_IF(model_rank <= 100 AND bid_count_rank <= 100)
        AS shared_top_100,

    COUNT_IF(model_rank <= 100 AND bid_count_rank > 100)
        AS model_only_top_100,

    COUNT_IF(bid_count_rank <= 100 AND model_rank > 100)
        AS bid_count_only_top_100

FROM ranked;


-- 10. WEIGHT SENSITIVITY ANALYSIS
-- Compare three weighting scenarios to see how changes in the weights affect the top 100 selection

WITH scores AS (
    SELECT
        item_id,

        -- A: Current model (50/25/25)
        prioritisation_score AS score_a,

        -- B: More weight on engagement (60/20/20)
        engagement_score * 0.60
        + category_performance_score * category_confidence * 0.20
        + house_performance_score * house_confidence * 0.20
            AS score_b,

        -- C: More weight on historical performance (40/30/30)
        engagement_score * 0.40
        + category_performance_score * category_confidence * 0.30
        + house_performance_score * house_confidence * 0.30
            AS score_c

    FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_INTERMEDIATE.INT_ACTIVE_ITEM_PRIORITISATION
),

ranked AS (
    SELECT
        item_id,

        ROW_NUMBER() OVER (
            ORDER BY score_a DESC, item_id
        ) AS rank_a,

        ROW_NUMBER() OVER (
            ORDER BY score_b DESC, item_id
        ) AS rank_b,

        ROW_NUMBER() OVER (
            ORDER BY score_c DESC, item_id
        ) AS rank_c

    FROM scores
)

SELECT
    COUNT_IF(rank_a <= 100 AND rank_b <= 100)
        AS overlap_a_b,

    COUNT_IF(rank_a <= 100 AND rank_c <= 100)
        AS overlap_a_c,

    COUNT_IF(rank_b <= 100 AND rank_c <= 100)
        AS overlap_b_c

FROM ranked;


-- 11. NEXT-DAY TOP 10 COMPARISON
-- Compare the model's top 10 with a bid-count ranking
-- Only include items ending tomorrow or later
-- Recalculate both rankings within the eligible items

WITH eligible_items AS (
    SELECT
        item_id,
        current_bid_count,
        prioritisation_score
    FROM DBT_AUCTIONET.DBT_PAULINAARBAJANDEHLANG_MARTS.FCT_ACTIVE_ITEM_PRIORITISATION
    WHERE ends_at >= DATEADD('day', 1, CURRENT_DATE())
),

ranked AS (
    SELECT
        item_id,

        ROW_NUMBER() OVER (
            ORDER BY prioritisation_score DESC, item_id
        ) AS model_rank,

        ROW_NUMBER() OVER (
            ORDER BY current_bid_count DESC, item_id
        ) AS bid_count_rank

    FROM eligible_items
)

SELECT
    COUNT_IF(model_rank <= 10 AND bid_count_rank <= 10)
        AS shared_top_10,

    COUNT_IF(model_rank <= 10 AND bid_count_rank > 10)
        AS model_only_top_10,

    COUNT_IF(bid_count_rank <= 10 AND model_rank > 10)
        AS bid_count_only_top_10

FROM ranked;


-- 12. RAW DATA FRESHNESS
-- Check the latest ingestion and number of source files
-- This indicates data arrival, not successful dbt refresh

SELECT
    MAX(ingested_at) AS latest_ingestion,
    COUNT(DISTINCT file_path) AS source_files
FROM DBT_AUCTIONET.RAW.RAW_AUCTIONET_PAGINATED;
