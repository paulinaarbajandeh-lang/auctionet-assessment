
{{ config(
    materialized='table',
    schema='marts'
) }}

with auctions as (
    select
        item_id,
        ends_at,
        published_at
    from {{ ref('fct_auctions') }}
),

ranked_items as (
    select
        p.item_id,
        p.company_id,
        p.category_id,
        p.main_category_id,
        p.main_category_name,
        p.auction_house,

        a.ends_at,
        a.published_at,

        p.estimate_sek,
        p.starting_bid_amount_sek,

        p.current_bid_count,
        p.engagement_score,

        p.category_ended_items,
        p.category_median_bid_count,
        p.category_median_hammer_vs_estimate_pct,
        p.category_pct_above_estimate,
        p.category_confidence,

        p.house_ended_items,
        p.house_median_bid_count,
        p.house_median_hammer_vs_estimate_pct,
        p.house_pct_above_estimate,
        p.house_confidence,

        p.prioritisation_score,
        p.prioritisation_rank,

        row_number() over (
            order by p.current_bid_count desc, p.item_id
        ) as bid_count_rank

    from {{ ref('int_active_item_prioritisation') }} as p

    left join auctions as a
        on p.item_id = a.item_id
)

select
    *,

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

from ranked_items
