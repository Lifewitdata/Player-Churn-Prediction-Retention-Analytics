<div align="center">

<img src="https://img.shields.io/badge/Python-3.10-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
<img src="https://img.shields.io/badge/Jupyter-Notebook-F37626?style=for-the-badge&logo=jupyter&logoColor=white"/>
<img src="https://img.shields.io/badge/Pandas-Feature%20Engineering-150458?style=for-the-badge&logo=pandas&logoColor=white"/>
<img src="https://img.shields.io/badge/Scikit--Learn-ML%20Ready-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-Model%20Ready-2ea44f?style=for-the-badge"/>

# 📉 Player Churn Prediction & Retention Analytics

**25 business questions. 7 data sources. One model-ready master table — built to predict which B2B gaming operators will churn before they do.**

[Problem Statement](#problem) · [Pipeline](#pipeline) · [Feature Engineering](#features) · [Key Signals](#signals) · [ML Roadmap](#ml)

</div>

---

## 🧭 The Business Problem {#problem}

On a B2B gaming operator platform, losing an operator doesn't mean losing one user — it means losing their *entire player base*. This project answers:

- Which operators are most at risk of churning right now?
- What signals appear **weeks before churn** — before it's too late to act?
- Which features should a retention model be built on?

**Output:** A `master_churn_table.csv` — one row per operator, 20+ engineered features, ready to feed directly into a classification model.

---

## 📐 Analytical Pipeline {#pipeline}

```
┌────────────────────────────────────────────────────────────────────┐
│  RAW DATA  (7 sources)                                              │
│                                                                     │
│  operator_accounts   operator_revenue_monthly   player_sessions    │
│  payments_transactions   sportsbook_bets   game_catalog            │
│  (+ derived: master_churn_table)                                    │
└───────────────────────┬────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│  SECTION 1 — EDA & Churn Profiling  (Q1–Q6)                        │
│  Overall churn rate  ·  Plan tier breakdown  ·  Geography          │
│  Churn reasons  ·  Tenure analysis  ·  Feature distribution        │
└───────────────────────┬────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│  SECTION 2 — Revenue Trend Analysis  (Q7–Q11)                      │
│  Platform GGR trend (MoM)  ·  Per-operator GGR: first 3 vs last 3  │
│  Active player count trend  ·  Casino/Sports split  ·  Bonus costs │
└───────────────────────┬────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│  SECTION 3 — Player Engagement  (Q12–Q15)                          │
│  Session aggregation per operator  ·  Device mix                   │
│  Bonus usage rate  ·  Deposit conversion rate                      │
└───────────────────────┬────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│  SECTION 4 — Payment Health  (Q16–Q19)                             │
│  Failed/reversed transaction rate  ·  First deposit trend          │
│  Currency & payment method mix  ·  Geographic payment patterns     │
└───────────────────────┬────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│  SECTION 5 — Sportsbook  (Q20–Q22)                                 │
│  Operator margin trend  ·  Live bet ratio  ·  Market coverage      │
└───────────────────────┬────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│  SECTION 6 — Game Catalog Health  (Q23–Q25)                        │
│  GGR by provider & game type  ·  RTP / volatility correlation      │
│  Mobile-ready % · Active catalog %  ·  Bonus round availability    │
└───────────────────────┬────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│  SECTION 7 — MASTER CHURN TABLE                                    │
│  All 6 sections merged → one row per operator                      │
│  20+ engineered features  ·  Target: is_active (0 = churned)      │
│  Correlation matrix → feature importance ranking                   │
└────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Feature Engineering {#features}

The master churn table is built from scratch — every feature below is derived and validated:

### Revenue Features
| Feature | How It's Built | Why It Matters |
|---|---|---|
| `ggr_trend_pct` | % change: last 3 months GGR vs first 3 months | **#1 churn predictor** — declining revenue is the strongest early warning signal |
| `avg_total_ggr` | Mean monthly GGR across operator lifetime | Scale indicator — low-revenue operators are higher-risk |
| `avg_net_software_revenue` | Mean monthly net revenue to platform | Platform profitability perspective |
| `avg_bonus_cost_pct` | Mean bonus spend as % of GGR | High bonus dependency = unsustainable unit economics |
| `avg_casino_pct` | % of GGR from casino vertical | Single-vertical dependency correlates with churn |

### Engagement Features
| Feature | How It's Built | Why It Matters |
|---|---|---|
| `active_players_trend_pct` | % change: last 3 months players vs first 3 | Player count decline *precedes* revenue decline |
| `avg_session_duration` | Mean session length in minutes | Low engagement = at-risk operator |
| `bonus_used_rate` | Bonus sessions / total sessions | Heavy bonus dependency as churn signal |
| `deposit_rate` | Successful deposits / total deposit attempts | Conversion health — poor deposit UX drives exits |
| `device_mix` | Mobile vs desktop session split | Mobile-heavy operators on non-mobile catalogs churn more |

### Payment Features
| Feature | How It's Built | Why It Matters |
|---|---|---|
| `failed_txn_rate` | Failed + reversed txns / total txns | Payment friction is a top-3 churn driver |
| `first_deposit_trend` | New player first deposits MoM trend | Acquisition slowdown = structural problem |
| `payment_method_diversity` | Count of distinct payment methods used | Single payment method = operational fragility |

### Profile Features
| Feature | How It's Built | Why It Matters |
|---|---|---|
| `tenure_months` | `(churn_date or today) − join_date` / 30 | First 6 months are the highest-risk period |
| `plan_tier` | Categorical: Starter / Growth / Enterprise | Starter churns at significantly higher rate |
| `games_enabled` | Count of enabled games at signup | Platform investment indicator |
| `sports_markets_enabled` | Count of active sportsbook markets | Low setup = low commitment |

---

## 📡 Key Churn Signals {#signals}

### Signal 1 — GGR Decline (Strongest Predictor)
The majority of churned operators show **declining GGR in their last 3 months** vs their first 3 months. This is the single most reliable early warning signal and should trigger an immediate retention intervention.

### Signal 2 — Player Count Drops Before Revenue Does
Active player count decline precedes GGR decline — meaning the platform gets a **2–4 week early warning window** before revenue impact shows up if player trends are monitored proactively.

### Signal 3 — Payment Friction
High `failed_txn_rate` is consistently elevated among churned operators. When players can't deposit smoothly, operators lose confidence in the platform and exit.

### Signal 4 — Single Vertical Dependency
Operators earning 90%+ of their GGR from only casino *or* only sports churn at higher rates than operators with a balanced split. Over-dependence on one vertical = structural vulnerability.

### Signal 5 — Early Tenure Risk
The highest-churn window is the **first 6 months**. Churned operators have significantly shorter median tenure than active operators, confirming the importance of early onboarding and success milestones.

---

## 🤖 ML Readiness & Roadmap {#ml}

The `master_churn_table.csv` is ready to feed directly into classification models.

### Suggested Modelling Sequence

```
Step 1 — Baseline
  └── Logistic Regression (interpretable, fast, sets performance floor)

Step 2 — Non-linear
  └── Random Forest (captures feature interactions, built-in importance)

Step 3 — Boosting
  └── XGBoost / LightGBM (typically highest AUC on tabular churn data)

Step 4 — Explainability
  └── SHAP values on best model → operator-level churn explanations

Step 5 — Deployment
  └── Weekly batch scoring → flag operators with P(churn) > 0.70
      → Auto-trigger retention workflow (account manager outreach, discount offer)
```

### Evaluation Metrics
- Primary: **AUC-ROC** (handles class imbalance)
- Secondary: **Precision @ top decile** (focus retention spend on highest-risk operators)
- Business metric: **Churn rate reduction** in flagged cohort vs control (A/B tested)

---

## 🗂️ Dataset

| Table | Description |
|---|---|
| `operator_accounts.csv` | Profiles — plan tier, country, platform type, join/churn dates, churn reason |
| `operator_revenue_monthly.csv` | Monthly GGR (Casino + Sports), active players, bonus costs |
| `player_sessions.csv` | Session-level engagement — duration, device, bonus usage |
| `payments_transactions.csv` | Deposits/withdrawals — amounts, status, payment method |
| `sportsbook_bets.csv` | Bet volume, live bet flag, markets, operator margin |
| `game_catalog.csv` | RTP %, volatility, mobile-readiness, bonus rounds per game |

> All datasets are synthetic, designed to represent realistic B2B gaming operator schemas. No real operator data included.

---

## 🛠️ Tech Stack

| | Tool | Purpose |
|---|---|---|
| 🐍 | Python 3 · pandas · numpy | Pipeline, feature engineering, aggregations |
| 📊 | matplotlib · seaborn | 25+ charts across 7 analytical sections |
| 📐 | scipy.stats | Distribution comparisons, hypothesis tests |
| 🤖 | scikit-learn *(next step)* | Classification models on master table |
| 📓 | Jupyter Notebook | End-to-end reproducible analysis |

---

## 🚀 Run It Locally

```bash
# Clone
git clone https://github.com/your-username/player-churn-analytics.git
cd player-churn-analytics

# Install
pip install pandas numpy matplotlib seaborn scipy jupyter

# Run
jupyter notebook "Player_Churn_Prediction___Retention_Analytics.ipynb"
```

> Place all `.csv` source files in the same directory as the notebook before running.

---

## 📬 Contact

**[Isfaque Ansari]** · Data Analyst  
[isfaqueans6@gmail.com](mailto:your.email@example.com) · [LinkedIn](https://linkedin.com/in/isfaque-ansari-/) 
---

<div align="center">
  <sub>Built with Python · Part of GameZone Digital Analytics Portfolio</sub>
</div>
