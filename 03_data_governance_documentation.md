# Data Governance & Feature Documentation
## Player Churn Prediction & Retention Analytics

---

## 1. Data Sources & Ownership

| Source File | Description | Grain | Row Count | Refresh Cadence |
|---|---|---|---|---|
| `operator_accounts.csv` | Operator (B2B client) profile, plan, churn status | 1 row per operator | 80 | Daily |
| `operator_revenue_monthly.csv` | Monthly GGR, revenue, player & deposit volumes | 1 row per operator-month | 1,420 | Monthly |
| `player_sessions.csv` | Individual player gaming session logs | 1 row per session | 50,000 | Real-time / streaming |
| `payments_transactions.csv` | Deposit/withdrawal/bonus transaction logs | 1 row per transaction | 25,000 | Real-time / streaming |
| `sportsbook_bets.csv` | Sports betting activity and outcomes | 1 row per bet | 20,000 | Real-time / streaming |
| `game_catalog.csv` | Game metadata (RTP, volatility, mobile readiness) | 1 row per game | 8,000 | Weekly |

---

## 2. Feature Definitions (Master Churn Table)

| Field | Definition | Source / Calculation |
|---|---|---|
| `operator_id` | Unique operator identifier | `operator_accounts` |
| `plan_tier` | Subscription tier (Starter / Growth / Enterprise) | `operator_accounts` |
| `country` | Operator's primary market | `operator_accounts` |
| `platform_type` | Casino / Sportsbook / Both | `operator_accounts` |
| `monthly_fee_usd` | Monthly platform license fee | `operator_accounts` |
| `tenure_months` | Months between `join_date` and `churn_date` (or reference date if active) | `(churn_date OR 2024-12-31) - join_date`, in 30-day months |
| `games_enabled` | Number of casino games enabled for the operator | `operator_accounts` |
| `sports_markets_enabled` | Number of sportsbook markets enabled | `operator_accounts` |
| `payment_methods_count` | Number of supported payment methods | `operator_accounts` |
| `is_active` | Churn label (1 = active, 0 = churned) | `operator_accounts` |
| `avg_total_ggr` | Average monthly Gross Gaming Revenue | `AVG(total_ggr_usd)` over operator's history |
| `avg_net_software_revenue` | Average monthly net software revenue | `AVG(net_software_revenue_usd)` |
| `avg_active_players` | Average monthly active players | `AVG(active_players)` |
| `avg_bonus_cost_pct` | Average bonus spend as % of GGR | `AVG(bonus_cost_usd / total_ggr_usd * 100)` |
| `avg_casino_pct` | Average share of GGR from casino vertical | `AVG(casino_ggr_usd / total_ggr_usd * 100)` |
| `ggr_trend_pct` | % change in GGR: last 3 months avg vs. first 3 months avg | `(last_3m_avg - first_3m_avg) / first_3m_avg * 100` |
| `active_players_trend_pct` | % change in active players, same method as above | Same method, on `active_players` |
| `avg_session_duration` | Average player session length (minutes) | `AVG(duration_min)` from `player_sessions` |
| `avg_bets_placed` | Average bets placed per session | `AVG(bets_placed)` |
| `avg_wagered_usd` | Average amount wagered per session | `AVG(total_wagered_usd)` |
| `total_sessions` | Total session count for operator | `COUNT(session_id)` |
| `deposit_rate` | % of sessions resulting in a deposit | `AVG(deposit_made)` |
| `bonus_usage_rate` | % of sessions where a bonus was used | `AVG(bonus_used)` |
| `total_transactions` | Total payment transactions | `COUNT(transaction_id)` from `payments_transactions` |
| `failed_txn_rate` | % of transactions with status Failed/Reversed | `AVG(status IN ('Failed','Reversed'))` |
| `avg_processing_time_sec` | Average payment processing time | `AVG(processing_time_sec)` |
| `avg_fee_usd` | Average transaction fee | `AVG(fee_usd)` |
| `first_deposit_count` | Total first-time deposits (new player acquisition proxy) | `SUM(is_first_deposit)` |
| `total_bets` | Total sportsbook bets placed | `COUNT(bet_id)` from `sportsbook_bets` |
| `avg_stake_usd` | Average bet stake | `AVG(stake_usd)` |
| `avg_margin_usd` | Average operator margin per bet | `AVG(operator_margin_usd)` |
| `total_margin_usd` | Total operator margin from sportsbook | `SUM(operator_margin_usd)` |
| `live_bet_rate` | % of bets placed live (in-play) | `AVG(live_bet)` |
| `churned` (model target) | 1 = operator churned, 0 = still active | `1 - is_active` |
| `churn_risk_score_rf` | Predicted churn probability (Random Forest) | Model output, range 0-1 |
| `churn_risk_score_logreg` | Predicted churn probability (Logistic Regression) | Model output, range 0-1 |

---

## 3. Data Quality Standards

1. **Completeness**: All raw source files validated for null counts on join. Numeric model features with missing values (operators with <4 months of revenue history) are median-imputed; this affects 1-2 of 80 operators.
2. **Consistency**: Date fields (`join_date`, `churn_date`, `session_start`, `transaction_date`, `bet_date`) parsed and validated as proper datetime types at ingestion.
3. **Referential integrity**: All `operator_id` values in transactional tables (sessions, payments, bets) are validated against `operator_accounts` before joining into the master table; unmatched IDs are excluded and logged.
4. **Derived field validation**: Percentage fields (`casino_pct`, `sports_pct`, `bonus_pct_of_ggr`) are checked for valid 0-100 ranges and divide-by-zero guards (`NULLIF(denominator, 0)`).
5. **Churn label definition**: An operator is labeled "churned" only if `is_active = 0` AND a `churn_date` is populated; operators without a churn date default to active status as of the reference date (2024-12-31).

---

## 4. Refresh & Versioning

- **ETL pipeline**: `01_etl_master_churn_table.sql` rebuilds all staging tables and the master table from source CSVs on each run — fully reproducible, no manual steps.
- **Model retraining**: `02_churn_prediction_model.py` should be re-run whenever the master table is refreshed (recommended: monthly, aligned with `operator_revenue_monthly` cadence).
- **Output versioning**: `master_churn_table.csv` and `churn_risk_scores.csv` are timestamped on export for audit trail and historical model comparison.

---

## 5. Access & Usage Notes

- Player-level identifiers (`player_id`) are aggregated to operator level before being joined into the master table — no individual player PII is exposed in the analytical layer.
- Tableau dashboard data sources (`tableau_*.csv`) are pre-aggregated extracts intended for reporting only; row-level transactional data should be queried from the source tables directly if deeper drill-down is required.
