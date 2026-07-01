# 🤖 Predictive Analytics & MLOps Pipeline

This script implements a dual-layer predictive analytics engine designed to optimize blood supply chain management. It leverages gradient boosting for classification and regression, combined with time-series forecasting to generate actionable inventory insights.

## ⚙️ Pipeline Overview
The pipeline processes raw healthcare data through three main functional layers:

### 1. Data Processing & Feature Engineering
* **Data Ingestion:** Automatically parses multiple sheets from `Data_Model.xlsx`.
* **Feature Engineering:** Generates critical indicators including `coverage_ratio`, `demand_pressure`, `risk_score`, `efficiency_score`, and `scarcity_index` to train the predictive models.

### 2. Predictive Modeling Layer
The system employs two distinct machine learning models:
* **Deficit Regression:** An `XGBRegressor` trained to predict the precise numerical blood unit deficit at the hospital level.
* **Urgency Classification:** An `XGBClassifier` that assigns an `urgency_level` to facilities, providing binary-to-multiclass probability outputs.
* **Smart Risk Engine:** A proprietary weighted scoring system that combines predicted deficits, scarcity indices, and fulfillment rates to categorize hospital statuses into **🔴 Critical**, **🟡 Warning**, or **🟢 Stable**.

### 3. Forecasting & MLOps
* **Demand Forecasting:** Utilizes the **Facebook Prophet** library to perform time-series analysis on aggregate `total_required` data, generating a rolling 7-day predictive demand outlook.
* **MLOps/Auto-Retraining:** The pipeline features a performance-monitoring block that compares the Mean Absolute Error (MAE) of the new model against the stored `reg_model.pkl`. It only updates production assets if the new model achieves higher performance.

## 🛠️ Requirements
This script requires the following dependencies:
* `pandas`, `numpy`
* `joblib`
* `scikit-learn`
* `xgboost`
* `prophet`

## 🚀 Execution & Outputs
Run the script to automatically trigger the MLOps cycle and generate production files:
```bash
python Predictive_Analytics_Pipeline.py
