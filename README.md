# Individual Project
# Auctionet – Marketplace Prioritisation

## Project Overview

This project explores how Auctionet can combine current bidder engagement with historical auction outcomes to identify which active items should be prioritised for marketplace visibility.

**Research question:**  
*How can Auctionet combine bidder engagement and historical auction outcomes to identify which active items should be prioritised for marketplace visibility?*

The main output is a rule-based prioritisation model and a set of Power BI dashboards designed to support a Marketplace Manager in selecting items for next-day promotional placement.

## Data Pipeline

The project uses the following data workflow:

**Auctionet API → Azure Data Factory → Azure Blob Storage → Snowflake → dbt → Power BI**

- **Azure Data Factory:** Collects active auction data through the Auctionet API.
- **Azure Blob Storage:** Stores the collected JSON files.
- **Snowflake:** Stores raw and transformed auction data.
- **dbt:** Cleans, transforms and combines current auction data with historical performance metrics.
- **Power BI:** Visualises the prioritisation results and supporting analysis.

Historical auction outcomes were also collected through a separate Python-based process.

## Prioritisation Model

Each active item receives a prioritisation score based on three components:

| Component | Weight |
|---|---:|
| Current bidder engagement | 50% |
| Historical category performance | 25% |
| Historical auction house performance | 25% |

Historical performance is adjusted using confidence factors based on the number of observations available.

The model ranks items by their overall score. It is a transparent, rule-based prototype rather than a statistically validated predictive model.

## Project Outputs

**1. Prioritisation model (dbt)**

The main SQL model is located at:

[`dbt/models/intermediate/int_active_item_prioritisation.sql`](dbt/models/intermediate/int_active_item_prioritisation.sql)

Supporting models calculate historical category and auction house performance and prepare the final prioritisation dataset for Power BI.

**2. Power BI dashboards**

The Power BI report contains three main pages:

- **Marketplace Prioritisation:** A Top 10 shortlist for next-day placement, ranking comparisons and historical performance metrics.
- **Worked Example:** An explanation of an individual item's score, including a breakdown of its contributing factors.
- **Marketplace Performance:** Historical category and auction house performance.

**Power BI report link:** To be added.

**3. Technical implementation**

The repository also includes project files for Azure Data Factory, Snowflake and dbt.

## How to Review the Project

1. Review the prioritisation model in `dbt/models/intermediate/`.
2. Explore the Power BI dashboards or their exported screenshots.
3. Refer to the Project Report for the methodology, design decisions, findings and limitations.

## Limitations

The prioritisation model uses manually selected weights and sample-size-based confidence factors. Historical data coverage is limited, currency conversion uses fixed exchange rates, and the model has not yet been validated against future auction outcomes or tested through a real placement experiment.

The project is intended as a decision-support prototype, not a proven method for increasing auction revenue.
