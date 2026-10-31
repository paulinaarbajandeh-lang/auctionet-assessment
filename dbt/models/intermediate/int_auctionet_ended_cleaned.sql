select
    item_id,
    auction_id,
    estimate,
    currency,
    company_id,
    auction_house,
    main_category_id,
    main_category_name,
    subcategory_id,
    subcategory_name,

    case
        when currency = 'SEK' then estimate
        when currency = 'EUR' then estimate * 11.10
        when currency = 'GBP' then estimate * 12.80
        when currency = 'DKK' then estimate * 1.49
        else null
    end as estimate_sek,

    bid_count,
    hammer_price_sek,
    hammer_price_sek - estimate_sek as hammer_vs_estimate_sek,

    case
        when estimate_sek > 0
        then hammer_price_sek / estimate_sek
        else null
    end as hammer_to_estimate_ratio,

    case
        when estimate_sek > 0
        then (hammer_price_sek - estimate_sek) / estimate_sek
        else null
    end as hammer_vs_estimate_pct,
    auction_end_time,
    reserve_met,
    url,
    source_page,
    has_bid_count,
    sale_format

from {{ ref('stg_auctionet_ended') }}