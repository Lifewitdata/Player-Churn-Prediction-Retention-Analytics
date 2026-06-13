/* ============================================================================
   ETL PIPELINE: Player Churn & Retention Analytics
   Source platforms: Operator Accounts, Revenue, Player Sessions,
                      Payments, Sportsbook Bets, Game Catalog
   Output: master_churn_table (one row per operator, model-ready features)
   ============================================================================ */

/* ----------------------------------------------------------------------
   STEP 1: Operator profile + tenure (EXTRACT + TRANSFORM)
   ---------------------------------------------------------------------- */
DROP TABLE IF EXISTS stg_operator_profile;
CREATE TABLE stg_operator_profile AS
SELECT
    operator_id,
    plan_tier,
    country,
    platform_type,
    monthly_fee_usd,
    games_enabled,
    sports_markets_enabled,
    payment_methods_count,
    is_active,
    join_date,
    churn_date,
    ROUND(
        (JULIANDAY(COALESCE(churn_date, '2024-12-31')) - JULIANDAY(join_date)) / 30.0
    , 1) AS tenure_months
FROM operator_accounts;


/* ----------------------------------------------------------------------
   STEP 2: Revenue summary + GGR / active-player trend (first 3 vs last 3 months)
   ---------------------------------------------------------------------- */
DROP TABLE IF EXISTS stg_revenue_summary;
CREATE TABLE stg_revenue_summary AS
SELECT
    operator_id,
    AVG(total_ggr_usd)              AS avg_total_ggr,
    AVG(net_software_revenue_usd)   AS avg_net_software_revenue,
    AVG(active_players)             AS avg_active_players,
    AVG(bonus_cost_usd * 100.0 / total_ggr_usd)   AS avg_bonus_cost_pct,
    AVG(casino_ggr_usd * 100.0 / total_ggr_usd)   AS avg_casino_pct
FROM operator_revenue_monthly
GROUP BY operator_id;

-- Trend tables: rank months per operator to grab first 3 / last 3
DROP TABLE IF EXISTS stg_revenue_ranked;
CREATE TABLE stg_revenue_ranked AS
SELECT
    operator_id,
    month,
    total_ggr_usd,
    active_players,
    ROW_NUMBER() OVER (PARTITION BY operator_id ORDER BY month ASC)  AS rn_asc,
    ROW_NUMBER() OVER (PARTITION BY operator_id ORDER BY month DESC) AS rn_desc,
    COUNT(*) OVER (PARTITION BY operator_id) AS n_months
FROM operator_revenue_monthly;

DROP TABLE IF EXISTS stg_revenue_trend;
CREATE TABLE stg_revenue_trend AS
SELECT
    operator_id,
    AVG(CASE WHEN rn_asc  <= 3 THEN total_ggr_usd END)  AS first_3m_ggr,
    AVG(CASE WHEN rn_desc <= 3 THEN total_ggr_usd END)  AS last_3m_ggr,
    AVG(CASE WHEN rn_asc  <= 3 THEN active_players END) AS first_3m_players,
    AVG(CASE WHEN rn_desc <= 3 THEN active_players END) AS last_3m_players
FROM stg_revenue_ranked
WHERE n_months >= 4
GROUP BY operator_id;

DROP TABLE IF EXISTS stg_revenue_trend_pct;
CREATE TABLE stg_revenue_trend_pct AS
SELECT
    operator_id,
    ROUND((last_3m_ggr - first_3m_ggr) * 100.0 / NULLIF(first_3m_ggr, 0), 2)         AS ggr_trend_pct,
    ROUND((last_3m_players - first_3m_players) * 100.0 / NULLIF(first_3m_players, 0), 2) AS active_players_trend_pct
FROM stg_revenue_trend;


/* ----------------------------------------------------------------------
   STEP 3: Player session engagement aggregates
   ---------------------------------------------------------------------- */
DROP TABLE IF EXISTS stg_session_agg;
CREATE TABLE stg_session_agg AS
SELECT
    operator_id,
    AVG(duration_min)        AS avg_session_duration,
    AVG(bets_placed)          AS avg_bets_placed,
    AVG(total_wagered_usd)    AS avg_wagered_usd,
    COUNT(session_id)         AS total_sessions,
    AVG(deposit_made)         AS deposit_rate,
    AVG(bonus_used)           AS bonus_usage_rate
FROM player_sessions
GROUP BY operator_id;


/* ----------------------------------------------------------------------
   STEP 4: Payment / transaction friction aggregates
   ---------------------------------------------------------------------- */
DROP TABLE IF EXISTS stg_payment_agg;
CREATE TABLE stg_payment_agg AS
SELECT
    operator_id,
    COUNT(transaction_id)                                                  AS total_transactions,
    AVG(CASE WHEN status IN ('Failed','Reversed') THEN 1.0 ELSE 0.0 END)   AS failed_txn_rate,
    AVG(processing_time_sec)                                               AS avg_processing_time_sec,
    AVG(fee_usd)                                                           AS avg_fee_usd,
    SUM(is_first_deposit)                                                  AS first_deposit_count
FROM payments_transactions
GROUP BY operator_id;


/* ----------------------------------------------------------------------
   STEP 5: Sportsbook performance aggregates
   ---------------------------------------------------------------------- */
DROP TABLE IF EXISTS stg_bet_agg;
CREATE TABLE stg_bet_agg AS
SELECT
    operator_id,
    COUNT(bet_id)               AS total_bets,
    AVG(stake_usd)               AS avg_stake_usd,
    AVG(operator_margin_usd)     AS avg_margin_usd,
    SUM(operator_margin_usd)     AS total_margin_usd,
    AVG(live_bet)                AS live_bet_rate
FROM sportsbook_bets
GROUP BY operator_id;


/* ----------------------------------------------------------------------
   STEP 6: MASTER CHURN TABLE — join all platforms into model-ready table
   ---------------------------------------------------------------------- */
DROP TABLE IF EXISTS master_churn_table;
CREATE TABLE master_churn_table AS
SELECT
    p.operator_id,
    p.plan_tier,
    p.country,
    p.platform_type,
    p.monthly_fee_usd,
    p.tenure_months,
    p.games_enabled,
    p.sports_markets_enabled,
    p.payment_methods_count,
    p.is_active,
    r.avg_total_ggr,
    r.avg_net_software_revenue,
    r.avg_active_players,
    r.avg_bonus_cost_pct,
    r.avg_casino_pct,
    t.ggr_trend_pct,
    t.active_players_trend_pct,
    s.avg_session_duration,
    s.avg_bets_placed,
    s.avg_wagered_usd,
    s.total_sessions,
    s.deposit_rate,
    s.bonus_usage_rate,
    pay.total_transactions,
    pay.failed_txn_rate,
    pay.avg_processing_time_sec,
    pay.avg_fee_usd,
    pay.first_deposit_count,
    b.total_bets,
    b.avg_stake_usd,
    b.avg_margin_usd,
    b.total_margin_usd,
    b.live_bet_rate
FROM stg_operator_profile p
LEFT JOIN stg_revenue_summary    r   ON p.operator_id = r.operator_id
LEFT JOIN stg_revenue_trend_pct  t   ON p.operator_id = t.operator_id
LEFT JOIN stg_session_agg        s   ON p.operator_id = s.operator_id
LEFT JOIN stg_payment_agg        pay ON p.operator_id = pay.operator_id
LEFT JOIN stg_bet_agg            b   ON p.operator_id = b.operator_id;


/* ============================================================================
   ANALYTICAL QUERIES (matches notebook EDA — answers Q1-Q25)
   ============================================================================ */

-- Q1: Overall churn rate
SELECT
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END)                       AS churned,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END)                       AS active,
    ROUND(100.0 * SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM operator_accounts;

-- Q2: Churn rate by plan tier
SELECT
    plan_tier,
    COUNT(*)                                                              AS total,
    SUM(is_active)                                                        AS active,
    COUNT(*) - SUM(is_active)                                             AS churned,
    ROUND(100.0 * (COUNT(*) - SUM(is_active)) / COUNT(*), 2)              AS churn_rate_pct
FROM operator_accounts
GROUP BY plan_tier
ORDER BY churn_rate_pct DESC;

-- Q3: Churn rate by country
SELECT
    country,
    COUNT(*)                                                              AS total,
    SUM(is_active)                                                        AS active,
    COUNT(*) - SUM(is_active)                                             AS churned,
    ROUND(100.0 * (COUNT(*) - SUM(is_active)) / COUNT(*), 2)              AS churn_rate_pct
FROM operator_accounts
GROUP BY country
ORDER BY churn_rate_pct DESC;

-- Q5: Churn reason breakdown
SELECT churn_reason, COUNT(*) AS operators
FROM operator_accounts
WHERE is_active = 0
GROUP BY churn_reason
ORDER BY operators DESC;

-- Q19: Top payment method per operator vs churn status
WITH method_counts AS (
    SELECT operator_id, payment_method, COUNT(*) AS cnt,
           ROW_NUMBER() OVER (PARTITION BY operator_id ORDER BY COUNT(*) DESC) AS rnk
    FROM payments_transactions
    GROUP BY operator_id, payment_method
)
SELECT
    m.payment_method,
    ROUND(AVG(1 - o.is_active), 2) AS churn_rate,
    ROUND(AVG(o.is_active), 2)     AS active_rate
FROM method_counts m
JOIN operator_accounts o ON m.operator_id = o.operator_id
WHERE m.rnk = 1
GROUP BY m.payment_method
ORDER BY churn_rate DESC;

-- Feature correlation proxy: avg key metrics by churn status (master table)
SELECT
    is_active,
    ROUND(AVG(tenure_months), 2)        AS avg_tenure_months,
    ROUND(AVG(failed_txn_rate), 4)      AS avg_failed_txn_rate,
    ROUND(AVG(ggr_trend_pct), 2)        AS avg_ggr_trend_pct,
    ROUND(AVG(active_players_trend_pct), 2) AS avg_player_trend_pct,
    ROUND(AVG(first_deposit_count), 2)  AS avg_first_deposit_count
FROM master_churn_table
GROUP BY is_active;
