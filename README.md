<div align="center">

<img src="https://img.shields.io/badge/Python-3.10-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
<img src="https://img.shields.io/badge/Jupyter-Notebook-F37626?style=for-the-badge&logo=jupyter&logoColor=white"/>
<img src="https://img.shields.io/badge/SQL-ETL%20Pipeline-003B57?style=for-the-badge&logo=sqlite&logoColor=white"/>
<img src="https://img.shields.io/badge/Pandas-Feature%20Engineering-150458?style=for-the-badge&logo=pandas&logoColor=white"/>
<img src="https://img.shields.io/badge/Scikit--Learn-ML%20Ready-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-Model%20Ready-2ea44f?style=for-the-badge"/>

# 📉 Player Churn Prediction & Retention Analytics

### 25 business questions. 6 data sources. 1 SQL ETL pipeline. 1 model-ready master table.
### Built to predict which B2B gaming operators will churn — before they do.

[Problem Statement](#-the-business-problem) · [Files](#-project-files) · [SQL ETL Pipeline](#-sql-etl-pipeline) · [Python Analysis](#-python-analysis-notebook) · [Features](#-feature-engineering--master-churn-table) · [Churn Signals](#-key-churn-signals) · [ML Roadmap](#-ml-roadmap)

</div>

---

## 🧭 The Business Problem

On a B2B iGaming operator platform, losing one operator doesn't mean losing one user — it means losing their **entire player base**. This project builds the analytical foundation to answer three critical questions:

```
1. Which operators are most at risk of churning right now?
2. What behavioural signals appear BEFORE churn — while there's still time to act?
3. Which features should a predictive retention model be built on?
```

The project is delivered in two layers:
- A **production-grade SQL ETL pipeline** (`Churn_Prediction___Retention_Analytics.sql`) that builds the master table from raw source tables
- A **Python EDA notebook** (`Player_Churn_Prediction___Retention_Analytics.ipynb`) that answers 25 business questions across 7 analytical sections and validates every feature

---

## 📁 Project Files

```
├── Player_Churn_Prediction___Retention_Analytics.ipynb   # Python EDA — 25 questions, 7 sections
├── Churn_Prediction___Retention_Analytics.sql            # SQL ETL pipeline — 6 staging tables → master
├── master_churn_table.csv                                # Output: model-ready feature matrix
├── operator_accounts.csv                                 # Source data
├── operator_revenue_monthly.csv                          # Source data
├── player_sessions.csv                                   # Source data
├── payments_transactions.csv                             # Source data
├── sportsbook_bets.csv                                   # Source data
└── game_catalog.csv                                      # Source data
```

---

## 🗄️ SQL ETL Pipeline

The SQL file (`Churn_Prediction___Retention_Analytics.sql`) is a **complete, production-ready ETL pipeline** that transforms 6 raw source tables into a single model-ready `master_churn_table` — one row per operator, 31 engineered columns.

### Pipeline Architecture

```
 operator_accounts          → stg_operator_profile     (tenure_months calculated via JULIANDAY)
 operator_revenue_monthly   → stg_revenue_summary      (avg GGR, bonus %, casino %)
                            → stg_revenue_ranked        (ROW_NUMBER() ASC + DESC — window fn)
                            → stg_revenue_trend         (first 3 months vs last 3 months)
                            → stg_revenue_trend_pct     (ggr_trend_pct, players_trend_pct)
 player_sessions            → stg_session_agg           (duration, bets, wager, deposit rate)
 payments_transactions      → stg_payment_agg           (failed_txn_rate, processing time)
 sportsbook_bets            → stg_bet_agg               (margin, live_bet_rate, stake)
                                      ↓
                            master_churn_table           (6-way LEFT JOIN — 31 columns)
```

### Key SQL Techniques Used

| Technique | Where Used | Purpose |
|---|---|---|
| `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY)` | `stg_revenue_ranked` | Rank months per operator to isolate first 3 / last 3 |
| `COUNT(*) OVER (PARTITION BY operator_id)` | `stg_revenue_ranked` | Filter operators with < 4 months of history |
| Conditional `AVG(CASE WHEN rn_asc <= 3 THEN ... END)` | `stg_revenue_trend` | Compute first-3 and last-3 month averages in one pass |
| `JULIANDAY()` date arithmetic | `stg_operator_profile` | Precise tenure calculation in months |
| `NULLIF(..., 0)` in division | `stg_revenue_trend_pct` | Safe division — avoids divide-by-zero on new operators |
| `COALESCE(churn_date, '2024-12-31')` | `stg_operator_profile` | Active operators use reference date instead of NULL |
| 6-way `LEFT JOIN` | `master_churn_table` | Preserve all operators even with sparse data in some tables |
| `DROP TABLE IF EXISTS` pattern | All staging tables | Idempotent pipeline — safe to re-run anytime |

### Analytical Queries in SQL (Matches Notebook EDA)

The SQL file also includes analytical queries that mirror the Python EDA:

```sql
-- Q1: Overall churn rate
-- Q2: Churn rate by plan tier  
-- Q3: Churn rate by country
-- Q5: Churn reason breakdown
-- Q19: Top payment method vs churn status (window function + join)
-- Feature signal validation: avg key metrics by churn status (from master table)
```

---

## 🐍 Python Analysis Notebook

The notebook (`Player_Churn_Prediction___Retention_Analytics.ipynb`) replicates the SQL logic in pandas and answers **25 business questions** across **7 analytical sections**:

```
SECTION 1 — EDA & Churn Profiling                     (Q1 – Q6)
┌─────────────────────────────────────────────────────────────────┐
│ Q1. Overall churn rate (Active vs Churned count + bar chart)    │
│ Q2. Churn rate by plan_tier — Starter vs Enterprise             │
│ Q3. Churn rate by country — geographic concentration           │
│ Q4. Feature distributions at signup: monthly_fee, games_enabled,│
│     sports_markets_enabled, payment_methods_count               │
│     → Do churned operators look different from day one?         │
│ Q5. churn_reason breakdown — top causes of exit                 │
│ Q6. Tenure analysis: join_date → churn_date in months           │
│     Median tenure compared: Active vs Churned                   │
└─────────────────────────────────────────────────────────────────┘

SECTION 2 — Revenue Trend Analysis                    (Q7 – Q11)
┌─────────────────────────────────────────────────────────────────┐
│ Q7.  Total platform GGR trend month-over-month                  │
│ Q8.  Per-operator GGR: first 3 months vs last 3 months          │
│      → How many churned ops show declining GGR before exit?     │
│ Q9.  active_players trend before churn                          │
│      → Does player count drop before revenue does?              │
│ Q10. Casino GGR % vs Sports GGR % split                        │
│      → Single-vertical dependency vs balanced split             │
│ Q11. bonus_cost_usd as % of GGR                                │
│      → Are churned operators burning more on bonuses?           │
└─────────────────────────────────────────────────────────────────┘

SECTION 3 — Player Engagement (player_sessions.csv)   (Q12 – Q15)
┌─────────────────────────────────────────────────────────────────┐
│ Q12. Aggregate per operator: avg_session_duration, avg_bets,    │
│      avg_wagered_usd, total_sessions, deposit_rate,             │
│      bonus_usage_rate → Active vs Churned comparison            │
│ Q13. Device mix: mobile vs desktop session share per operator   │
│ Q14. bonus_used rate — heavy bonus dependency as churn signal   │
│ Q15. deposit_made rate per session — conversion health          │
└─────────────────────────────────────────────────────────────────┘

SECTION 4 — Payment Health (payments_transactions.csv)(Q16 – Q19)
┌─────────────────────────────────────────────────────────────────┐
│ Q16. Failed/Reversed transaction rate — payment friction        │
│ Q17. avg_processing_time_sec — speed as a retention factor      │
│ Q18. is_first_deposit count trend — is new player acquisition   │
│      slowing down for churned operators?                        │
│ Q19. Payment method mix vs churn rate                           │
│      (cross-tab: top payment method per operator × is_active)  │
└─────────────────────────────────────────────────────────────────┘

SECTION 5 — Sportsbook (sportsbook_bets.csv)          (Q20 – Q22)
┌─────────────────────────────────────────────────────────────────┐
│ Q20. operator_margin_usd per bet — sportsbook profitability     │
│ Q21. live_bet ratio — live betting as modernity/engagement flag │
│ Q22. Bet volume trend: first 3 months vs last 3 months          │
│      → Do churned operators show declining bet activity?        │
└─────────────────────────────────────────────────────────────────┘

SECTION 6 — Game Catalog Health (game_catalog.csv)    (Q23 – Q25)
┌─────────────────────────────────────────────────────────────────┐
│ Q23. GGR by provider and game_type                              │
│ Q24. RTP % and volatility correlation with session duration     │
│      and total GGR (merged catalog × session data)             │
│ Q25. % catalog that is_active + mobile_ready + has_bonus_round  │
│      → Stale / non-mobile catalogs vs operator churn           │
└─────────────────────────────────────────────────────────────────┘

SECTION 7 — Master Churn Table
┌─────────────────────────────────────────────────────────────────┐
│ Recompute all staging aggregates using a clean compute_trend()  │
│ utility function (mirrors SQL window function logic in pandas)  │
│ 5-way LEFT merge → one row per operator → 31 columns            │
│ Saved as master_churn_table.csv                                 │
│ Boxplot comparison of 6 key features (Active vs Churned)        │
│ Correlation matrix → feature importance ranking                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Feature Engineering — Master Churn Table

`master_churn_table.csv` has **31 columns** — one row per operator, target variable `is_active`.

### Profile Features (from `operator_accounts`)
| Feature | How It's Built |
|---|---|
| `tenure_months` | `(COALESCE(churn_date, '2024-12-31') − join_date) / 30` via `JULIANDAY()` in SQL / `pd.Timedelta` in Python |
| `plan_tier` | Categorical: Starter / Growth / Enterprise |
| `monthly_fee_usd` | Raw — platform tier pricing signal |
| `games_enabled` | Count of games enabled at signup |
| `sports_markets_enabled` | Count of active sportsbook markets |
| `payment_methods_count` | Diversity of payment options |

### Revenue Features (from `operator_revenue_monthly`)
| Feature | How It's Built |
|---|---|
| `ggr_trend_pct` | `((last 3m avg GGR − first 3m avg GGR) / first 3m avg GGR) × 100` — using `ROW_NUMBER()` window in SQL |
| `active_players_trend_pct` | Same logic on `active_players` column |
| `avg_total_ggr` | Mean monthly GGR across operator lifetime |
| `avg_net_software_revenue` | Mean net revenue to platform monthly |
| `avg_active_players` | Mean active player count monthly |
| `avg_bonus_cost_pct` | `AVG(bonus_cost_usd / total_ggr_usd × 100)` |
| `avg_casino_pct` | `AVG(casino_ggr_usd / total_ggr_usd × 100)` — vertical concentration signal |

### Engagement Features (from `player_sessions`)
| Feature | How It's Built |
|---|---|
| `avg_session_duration` | Mean `duration_min` per operator |
| `avg_bets_placed` | Mean bets per session per operator |
| `avg_wagered_usd` | Mean wager amount per session |
| `total_sessions` | Count of all sessions for operator's players |
| `deposit_rate` | Mean of `deposit_made` (0/1) per session |
| `bonus_usage_rate` | Mean of `bonus_used` (0/1) per session |

### Payment Features (from `payments_transactions`)
| Feature | How It's Built |
|---|---|
| `failed_txn_rate` | `AVG(CASE WHEN status IN ('Failed','Reversed') THEN 1.0 ELSE 0.0 END)` |
| `avg_processing_time_sec` | Mean payment processing time |
| `avg_fee_usd` | Mean transaction fee |
| `total_transactions` | Total payment volume |
| `first_deposit_count` | Sum of `is_first_deposit` — acquisition health |

### Sportsbook Features (from `sportsbook_bets`)
| Feature | How It's Built |
|---|---|
| `total_bets` | Count of all bets placed |
| `avg_stake_usd` | Mean bet stake |
| `avg_margin_usd` | Mean operator margin per bet |
| `total_margin_usd` | Total sportsbook profitability |
| `live_bet_rate` | Mean of `live_bet` (0/1) — modernity signal |

---

## 📡 Key Churn Signals

### Signal 1 — GGR Decline (Strongest Predictor)
Churned operators consistently show declining GGR in their **final 3 months vs their opening 3 months**. This is the earliest and most reliable warning signal available — and it's confirmed in both the SQL analytical query and Python `ggr_trend_df` histogram.

### Signal 2 — Player Count Drops Before Revenue Does
The notebook's Q9 analysis (`players_trend_df`) shows active player count declines **ahead of GGR decline** — giving the retention team a 2–4 week early-warning window if player metrics are monitored proactively.

### Signal 3 — Payment Friction
`failed_txn_rate` is consistently higher among churned operators (Q16). When players can't deposit smoothly, operators lose trust in the platform and exit. The `avg_processing_time_sec` comparison (Q17) reinforces this — slower payments correlate with higher churn.

### Signal 4 — New Player Acquisition Slowdown
Q18 (`fd_trend_df`) tracks `is_first_deposit` trends over time. Churned operators show declining new-player acquisition months before their GGR collapses — it's a structural signal, not a temporary dip.

### Signal 5 — Low Live Betting Adoption
Q21 (`live_bet_rate`) shows that churned operators have lower live betting engagement. Operators not using modern platform features are less invested in the product and more likely to leave.

### Signal 6 — Short Tenure = High Risk
Q6 tenure analysis shows churned operators have a significantly shorter median tenure than active ones. The **first 6 months are the highest-risk window** — confirmed by the tenure distribution histogram.

---

## 📊 Visualisations Produced (Python Notebook)

| Chart | Type | Section |
|---|---|---|
| Active vs Churned operator count | Bar | Q1 |
| Churn rate by plan tier | Bar | Q2 |
| Churn rate by country | Bar | Q3 |
| Monthly fee / games_enabled / markets (Active vs Churned) | Boxplot × 4 | Q4 |
| Churn reasons (churned operators only) | Bar | Q5 |
| Tenure distribution: Active vs Churned | KDE histogram | Q6 |
| Total platform GGR trend (MoM) | Line | Q7 |
| GGR % change distribution (churned operators) | Histogram | Q8 |
| Casino GGR % distribution (Active vs Churned) | Boxplot | Q10 |
| Avg session duration + avg wagered (Active vs Churned) | Boxplot × 2 | Q12 |
| Mobile session share (Active vs Churned) | Boxplot | Q13 |
| Bonus usage rate (Active vs Churned) | Boxplot | Q14 |
| Deposit conversion rate (Active vs Churned) | Boxplot | Q15 |
| Failed transaction rate (Active vs Churned) | Boxplot | Q16 |
| Avg processing time (Active vs Churned) | Boxplot | Q17 |
| Avg operator margin per bet (Active vs Churned) | Boxplot | Q20 |
| Live bet adoption (Active vs Churned) | Boxplot | Q21 |
| GGR by game provider | Bar | Q23 |
| GGR by game type | Bar | Q23 |
| 6 key features side-by-side (Active vs Churned) | Boxplot grid | Section 7 |
| Feature correlation with is_active | Horizontal bar | Section 7 |

---

## 🤖 ML Roadmap

The `master_churn_table.csv` is ready to feed directly into classification models. Recommended sequence:

```
Step 1 — Baseline
  └── Logistic Regression (interpretable, fast, sets AUC floor)

Step 2 — Non-linear
  └── Random Forest (captures feature interactions, built-in importance)

Step 3 — Boosting
  └── XGBoost / LightGBM (typically highest AUC on tabular churn data)

Step 4 — Explainability
  └── SHAP values on best model → per-operator churn reason output

Step 5 — Deployment
  └── Weekly batch scoring via SQL pipeline → flag operators with P(churn) > 0.70
      → Auto-trigger retention workflow (account manager outreach / offer)
```

**Evaluation metrics:**
- Primary: **AUC-ROC** — handles class imbalance in churn datasets
- Secondary: **Precision @ top decile** — focus retention spend on highest-risk operators
- Business metric: **Churn rate reduction** in flagged cohort vs control (A/B tested)

---

## 🗂️ Source Datasets

| Table | Description | Key Columns |
|---|---|---|
| `operator_accounts.csv` | Operator profiles + churn status | `operator_id`, `plan_tier`, `country`, `is_active`, `join_date`, `churn_date`, `churn_reason` |
| `operator_revenue_monthly.csv` | Monthly GGR + player counts | `operator_id`, `month`, `total_ggr_usd`, `casino_ggr_usd`, `sports_ggr_usd`, `active_players`, `bonus_cost_usd` |
| `player_sessions.csv` | Session-level engagement | `session_id`, `operator_id`, `duration_min`, `bets_placed`, `total_wagered_usd`, `device`, `deposit_made`, `bonus_used`, `provider`, `game_type`, `ggr_usd` |
| `payments_transactions.csv` | Deposit/withdrawal transactions | `transaction_id`, `operator_id`, `status`, `processing_time_sec`, `fee_usd`, `is_first_deposit`, `payment_method`, `transaction_date` |
| `sportsbook_bets.csv` | Bet-level sportsbook data | `bet_id`, `operator_id`, `stake_usd`, `operator_margin_usd`, `live_bet`, `bet_date` |
| `game_catalog.csv` | Game-level catalog data | `game_id`, `provider`, `game_type`, `rtp_pct`, `volatility`, `mobile_ready`, `is_active`, `has_bonus_round`, `launch_date` |

> All datasets are synthetic, designed to represent realistic B2B iGaming operator schemas. No real operator data is included.

---

## 🛠️ Tech Stack

| | Tool | Purpose |
|---|---|---|
| 🐍 | Python 3 · pandas · numpy | EDA, feature engineering, 25-question analysis |
| 📊 | matplotlib · seaborn | 21 charts across 7 analytical sections |
| 🗄️ | **SQL (SQLite-compatible)** | Production ETL — 6 staging tables → master churn table |
| 🔬 | scipy.stats | Distribution comparison, correlation analysis |
| 🤖 | scikit-learn *(next step)* | Classification models on master table |
| 📓 | Jupyter Notebook | End-to-end reproducible analysis |

---

## 🚀 Run It Locally

```bash
# Clone
git clone https://github.com/your-username/player-churn-analytics.git
cd player-churn-analytics

# Install Python dependencies
pip install pandas numpy matplotlib seaborn scipy jupyter

# Run the EDA notebook
jupyter notebook "Player_Churn_Prediction___Retention_Analytics.ipynb"
```

**To run the SQL ETL pipeline:**
```sql
-- Run in any SQLite-compatible client (DB Browser, DBeaver, etc.)
-- Ensure all 6 source CSVs are imported as tables first, then execute:
-- Churn_Prediction___Retention_Analytics.sql
-- This produces master_churn_table with 31 columns, one row per operator.
```

> Place all `.csv` source files in the same directory as the notebook before running.

---

## 📬 Contact

**Isfaque Ansari** · Data Analyst  
[isfaq.ans@gmail.com](isfaq.ans@gmail.com) · [LinkedIn](https://linkedin.com/in/isfaque-ansari-/) 

---

<div align="center">
  <sub>Built with Python & SQL · B2B iGaming Churn Analytics · Reference Date: 2024-12-31</sub>
</div>
