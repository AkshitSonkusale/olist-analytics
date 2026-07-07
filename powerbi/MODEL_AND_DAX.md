# Power BI — Model, DAX & Dashboard

> Power BI Desktop is free but **Windows-only**. Not on Windows? The exports in `outputs/` open directly in Looker Studio, Tableau Public, or Metabase — the model/measures below translate almost 1:1.

## 1. Get data
Preferred: **Get Data → PostgreSQL**, import the four views: `v_rfm`, `v_cohort`, `v_monthly_kpis`, `v_category_revenue`. Connecting live to the DB is what makes the "SQL → BI pipeline" story real in an interview.

Fallback: **Get Data → Text/CSV** on the five files in `outputs/`.

## 2. Data model (star schema)
Build a proper model rather than dumping tables into visuals.

- **Date table** (create one, mark as a date table):
  ```
  DateTable = CALENDAR (DATE(2016,9,1), DATE(2018,10,31))
  ```
  Add `Year`, `Month`, `MonthStart = DATE(YEAR([Date]),MONTH([Date]),1)`.
- **Fact:** `v_monthly_kpis` (summary grain) and/or `v_rfm` (customer grain).
- **Dimensions:** the `segment` column in `v_rfm`, `category` in `v_category_revenue`, and the Date table.
- **Relationships:** single-direction, one-to-many from dimensions → fact. Join `DateTable[MonthStart]` → `v_monthly_kpis[month]`. *Do not* set bidirectional cross-filter — it double-counts revenue; being able to explain why is a good interview beat.

## 3. DAX measures (start with these)
```DAX
Total Revenue  = SUM ( v_monthly_kpis[revenue] )
Total Orders   = SUM ( v_monthly_kpis[orders] )
AOV            = DIVIDE ( [Total Revenue], [Total Orders] )

Customers            = DISTINCTCOUNT ( v_rfm[customer_unique_id] )
Segment Revenue      = SUM ( v_rfm[monetary] )
Segment Revenue %    =
    DIVIDE ( [Segment Revenue],
             CALCULATE ( [Segment Revenue], ALL ( v_rfm[segment] ) ) )

Repeat Buyer Count   = CALCULATE ( [Customers], v_rfm[frequency] >= 2 )
Repeat Revenue %     =
    DIVIDE ( CALCULATE ( [Segment Revenue], v_rfm[frequency] >= 2 ),
             [Segment Revenue] )
```

## 4. Dashboard — 4 pages (no more)
1. **Executive KPIs** — cards (Total Revenue, Total Orders, AOV, Customers) + a revenue-over-time line from `v_monthly_kpis`. Add a MoM trend.
2. **Customer Segments** — bar of `Segment Revenue %` by segment + a table (customers, avg value, avg recency). Headline: a few segments drive ~56% of revenue.
3. **Cohort Retention** — Matrix visual: rows = `cohort_month`, columns = `month_offset`, values = `active_customers`, conditional-formatted as a heatmap. Add a text box stating the ~3% repeat rate so the sparse right-hand side reads as insight, not an empty chart.
4. **Geography & Category** — top categories bar from `v_category_revenue` (health_beauty, watches_gifts, bed_bath_table lead) + a Brazil state map if you load `customer_state`.

## 5. Ship it
Publish a screenshot of each page into the repo README, or export to PDF and link it. A dashboard nobody can see doesn't count — the screenshot in your GitHub is what a recruiter actually opens.
