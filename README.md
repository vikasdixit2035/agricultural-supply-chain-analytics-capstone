# Agricultural Supply Chain Analytics — Capstone Project

An end-to-end management-consulting-style analytics capstone evaluating agricultural supply chain operations, cold-chain integrity, perishability economics, lot-level traceability, and working capital optimization.

---

## 📌 Executive Summary & Scenario

Supporting the executive leadership team (COO, Chief Procurement Officer, Head of Quality, Head of Logistics, and CFO) of **AgriFlow Foods**, a synthetic multi-category agricultural sourcing and distribution enterprise handling grains, fruits, and vegetables across ambient and cold-chain channels.

### Key Executive Baseline Metrics
- **Procurement Spend:** ₹47.60B across contract and spot farm purchases
- **Sales Revenue:** ₹7.53B across retail, processing, wholesale, HORECA, and export channels
- **Average Order Fill Rate:** 94.15%
- **On-Time In-Full (OTIF):** 10.93% (constrained by transport delays and dispatch bottlenecks)
- **Quality Rejection Rate at Source:** 6.22% (rejections on Brix, moisture, grade, and pesticide residues)
- **Transport Transit Loss Rate:** 5.81%
- **Cold-Chain Temperature Excursions:** 52.93% of reefer dispatches experienced temperature deviations
- **Annual Spoilage & Expiry Loss:** ₹578.76M
- **Demand Forecasting Accuracy:** 10.38% WAPE (Weighted Absolute Percentage Error on holdout test)
- **Simulated Contamination Recall:** Rapid backward/forward trace identified 19 affected customers and orders for lot `LOT0005168` within minutes

---

## 🛠️ Tech Stack & Workflow

```
Raw CSV / Excel ➔ PostgreSQL / SQL Relational Layer ➔ Python EDA & ML Demand Forecasting ➔ Power BI Semantic Model ➔ Excel Financial Sizing ➔ Executive Memo
```

- **Database / SQL:** PostgreSQL 15+ (Relational star/snowflake schema with 15 dimension and fact tables, data reconciliation logic, and 50 analytical business queries)
- **Python / Data Science:** Python 3.11+ (`pandas`, `numpy`, `scikit-learn`, `matplotlib`, `seaborn`) for cold-chain excursion diagnostics, supplier scorecards, safety stock calculations, and Random Forest holdout forecasting
- **BI & Visualisation:** Power BI semantic architecture, 20+ specialized DAX business measures, custom design theme JSON, and 7-page executive dashboard blueprint
- **Financial Scenario Modeling:** Excel Opportunity Sizing Model with Low / Base / High capture sensitivity analysis
- **Management Consulting Frameworks:** MECE Issue Tree, Hypothesis Register, 3-Tier KPI Value Driver Tree, Grading Rubric, and Executive Recommendation Memo

---

## 📂 Repository Structure

```text
├── 00_README/                  # Quickstart guide and sequence documentation
├── 01_Project_Brief/           # Learner brief (PDF & DOCX) and differentiator architectural memo
├── 02_Data/
│   ├── Raw/                    # Deliberately imperfect raw CSVs (farms, lots, shipments, quality, prices)
│   ├── Clean_Reference/        # Validated clean baseline datasets (15 dimension & fact tables)
│   └── Data_Dictionary_KPI_Catalog.xlsx
├── 03_SQL/
│   ├── 00_Load_Data.sql        # Database initialization and bulk ingest
│   ├── 01_Create_Schema.sql    # Relational schema definition and constraints
│   ├── 02_Cleaning_Solution.sql# End-to-end data reconciliation and cleaning scripts
│   ├── 03_Business_Questions_50.txt
│   └── 04_Solution_Queries_50.sql
├── 04_Python/
│   ├── Agricultural_Supply_Chain_Analytics_Learner.ipynb
│   ├── Agricultural_Supply_Chain_Analytics_Solution.ipynb
│   ├── Agricultural_Supply_Chain_Analytics_Solution_Executed.ipynb
│   └── requirements.txt
├── 05_PowerBI/                 # DAX measures, 7-page dashboard blueprint, theme JSON, reference report
├── 06_Consulting_Workflow/     # Issue tree, KPI tree, hypothesis register, instructor solution report
├── 07_Solution_Outputs/        # Exported analysis scorecards, holdout forecasts, charts, and opportunity sizing
├── 08_Submission_Templates/    # Blank student deliverable templates & evaluation rubric
├── PROJECT_MANIFEST.md         # Full inventory of all 81 project artifacts
├── START_HERE_LEARNER_WITH_SOLUTIONS.md
├── VALIDATION_REPORT.md        # Comprehensive data integrity and schema validation signoff
└── .gitignore
```

---

## 💡 Key Analytical Pillars

1. **Farm-to-Fork Traceability:** Lot-level genealogy tracking every customer shipment back to specific harvest batches, farms, and quality check records.
2. **Perishability Economics & FEFO:** Replacing naive FIFO inventory rotation with First-Expired-First-Out (FEFO) logic to minimize spoilage of shelf-life-constrained crops.
3. **Cold-Chain Assurance:** Reefer compliance monitoring, excursion severity scoring, and refrigerated carrier performance diagnostics.
4. **Procurement & Quality at Source:** Evaluating purchase price variances (PPV) against monthly market indices, moisture/Brix specifications, and supplier risk scores.
5. **Inventory Policy Optimization:** Dynamic safety stock and reorder point (ROP) modeling under stochastic demand and variable transit lead times.
6. **Executive Value Sizing:** Translating operational improvements into ₹300M–₹800M+ bottom-line and working capital impact scenarios.

---

## 🚀 Recommended Run Order

1. **Briefing:** Read `01_Project_Brief/Agricultural_Supply_Chain_Analytics_Learner_Brief.pdf` and explore `02_Data/Data_Dictionary_KPI_Catalog.xlsx`.
2. **Database Ingestion:** Set up tables using `03_SQL/01_Create_Schema.sql` and ingest raw datasets via `03_SQL/00_Load_Data.sql`.
3. **SQL Analytics:** Solve the 50 business questions in `03_SQL/03_Business_Questions_50.txt` (reference answers in `03_SQL/04_Solution_Queries_50.sql`).
4. **Python Exploratory Modeling:** Run `04_Python/Agricultural_Supply_Chain_Analytics_Learner.ipynb` for supplier scoring, cold-chain analytics, and machine learning demand forecasting.
5. **Business Intelligence:** Construct the multi-page Power BI dashboard following `05_PowerBI/02_Dashboard_Blueprint.md` and `05_PowerBI/01_DAX_Measures.dax`.
6. **Scenario Modeling:** Populate the sensitivity scenarios in `08_Submission_Templates/Supply_Chain_Opportunity_Model_Learner.xlsx`.
7. **Executive Storyline:** Synthesize findings into the `08_Submission_Templates/Executive_Recommendation_Memo_Template.md` using the consulting workflow frameworks in `06_Consulting_Workflow/`.

---

## 📄 Notes & Disclaimers

This repository contains synthetic business data generated for educational, portfolio, and analytical benchmarking purposes. The analytical workflows reflect best-practice management-consulting methodologies and do not reproduce proprietary methods or confidential data from any specific firm.
