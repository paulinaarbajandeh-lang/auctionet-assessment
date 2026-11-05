{{ config(
    materialized='table',
    schema='marts'
) }}

select
    item_id,
    company_id,
    category_id,
    main_category_id,
    main_category_name,
    auction_house,

    estimate_sek,
    starting_bid_amount_sek,

    current_bid_count,
    engagement_score,

    category_ended_items,
    category_median_bid_count,
    category_median_hammer_vs_estimate_pct,
    category_pct_above_estimate,
    category_confidence,

    house_ended_items,
    house_median_bid_count,
    house_median_hammer_vs_estimate_pct,
    house_pct_above_estimate,
    house_confidence,

    prioritisation_score,
    prioritisation_rank,

    row_number() over (
        order by current_bid_count desc, item_id
    ) as bid_count_rank,
    
    case
        when bid_count_rank <= 100
             and prioritisation_rank <= 100
            then 'Both Top 100'

        when prioritisation_rank <= 100
            then 'Priority Model Only'

        when bid_count_rank <= 100
            then 'Bid Count Only'

        else 'Outside Top 100'
    end as top_100_group
    ) as bid_count_rank

from {{ ref('int_active_item_prioritisation') }}