{{ config(
    materialized='view',
    schema='intermediate'
) }}

with ranked as (

    select
        *,

        percent_rank() over (
            order by current_bid_count
        ) as engagement_score

    from {{ ref('int_active_items_with_historical_performance') }}

),

base as (

    select
        *,

        coalesce(category_pct_above_estimate, 0) as category_performance_score,

        coalesce(house_pct_above_estimate, 0) as house_performance_score,

        case
            when category_ended_items >= 100 then 1.0
            when category_ended_items >= 30 then 0.75
            when category_ended_items >= 10 then 0.50
            else 0.25
        end as category_confidence,

        case
            when house_ended_items >= 100 then 1.0
            when house_ended_items >= 30 then 0.75
            when house_ended_items >= 10 then 0.50
            else 0.25
        end as house_confidence

    from ranked

),

scored as (

    select
        *,

        (
            engagement_score * 0.50
            +
            (category_performance_score * category_confidence) * 0.25
            +
            (house_performance_score * house_confidence) * 0.25
        ) as prioritisation_score

    from base

)

select
    *,
    rank() over (
        order by prioritisation_score desc
    ) as prioritisation_rank

from scored