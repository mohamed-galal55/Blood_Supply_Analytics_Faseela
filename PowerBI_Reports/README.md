# 📊 Faseela Executive Dashboard

## 📌 Core Objective
This Microsoft Power BI report serves as the definitive presentation layer for the Faseela pipeline. The objective is to transition from descriptive analytics (current stock) to prescriptive analytics (algorithmic shortage prevention).

---

## 📑 Dashboard Architecture & Report Pages

The Power BI report is structurally divided into six specialized analytical domains, each engineered to address specific operational and predictive facets of the blood supply chain:

### 1. Executive Overview
<img width="2050" height="1280" alt="Executive_Overview" src="https://github.com/user-attachments/assets/7e22a84d-1ddc-4dcb-95a4-58ffc3b6eafa" />

**Focus:** Macro-Level Supply Chain Equilibrium & High-Level KPI Tracking
Acts as the primary synthesis layer, providing health directors with an immediate pulse on the regional supply network.
* **Key Metrics:** Overall & Patient Fulfillment Rates, Hospitals in Shortage, Critical Pending Patients, and Donor Readiness Rate.
* **Core Visualizations:** Total Deficit by Governorate, Monthly Received vs. Patient Requests, and Urgency Level distribution.

### 2. Geography
<img width="2064" height="1166" alt="Geography" src="https://github.com/user-attachments/assets/5db9ee71-55af-481a-84f1-675bfcd5da99" />

**Focus:** Geospatial Triage & Regional Deficit Distribution
Maps the physical distribution of blood shortages to facilitate optimized routing and logistical decision-making.
* **Key Metrics:** Governorates in Shortage, Highest Deficit Governorate, and Best Covered Governorate.
* **Core Visualizations:** Geospatial bubble map plotting Hospital Total Deficit by latitude/longitude, and diverging bar charts contrasting Ready Donors vs. Critical Patients.

### 3. Blood Types
<img width="2060" height="1166" alt="Blood_Types" src="https://github.com/user-attachments/assets/10450e1c-7157-41e8-93bc-4ab2491a831c" />

**Focus:** Hematological Distribution & Type-Specific Deficit Tracking
Isolates supply chain bottlenecks down to specific blood types and Rh factors, ensuring clinical compatibility constraints are met.
* **Key Metrics:** Blood Types in Critical Status, Rarest Blood Type, Total Blood Deficit, and Best Covered Type metrics.
* **Core Visualizations:** Cross-tabular Matrix detailing Supply vs. Demand intersecting with Governorate, and comparative clustered bar charts evaluating total Patients vs. Donors per specific blood type.

### 4. Patients
<img width="2066" height="1170" alt="Patients" src="https://github.com/user-attachments/assets/ca414343-f6ef-4697-a7da-7a83cade1694" />

**Focus:** Clinical Demand Triage & Urgency Stratification
Analyzes the demand-side of the ecosystem, tracking patient request volume, fulfillment status, and critical medical needs.
* **Key Metrics:** Total Patients, Pending Patients, Critical Pending Patients, and Received Patients.
* **Core Visualizations:** Stacked bar charts breaking down Received vs. Pending patient statuses, trend lines tracking Monthly Patient Requests, and health status segmentation.

### 5. Donors
<img width="2062" height="1170" alt="Donors" src="https://github.com/user-attachments/assets/95ff89d3-7201-4f8f-b557-252481a47921" />

**Focus:** Supply-Side Readiness, Retention, & Demographic Stratification
Evaluates the capacity, reliability, and physical locations of the donor pool to proactively mitigate forecasted shortages.
* **Key Metrics:** Donor Readiness Rate, Committed Rate, Average Days to Next Donation, and Ready Donors Now.
* **Core Visualizations:** Demographic histograms categorizing Donor IDs by Age Group, bar charts calculating the Average Days to Next Donation, and geographic distribution mapping of Ready Donors.

### 6. AI Predictive Analytics
<img width="2068" height="1170" alt="AI Predictive Analytics 1" src="https://github.com/user-attachments/assets/930eb5cc-d982-4912-b397-e4db6d4788c8" />
<img width="2068" height="1174" alt="AI Predictive Analytics 2" src="https://github.com/user-attachments/assets/16e43c7e-0e23-4b64-9822-94dbea2c2845" />

**Focus:** Forward-Looking Resource Optimization & Algorithmic Risk Triage
Integrates machine learning classification (XGBoost) and time-series forecasting (Prophet) to transition the network from reactive monitoring to proactive shortage prevention. It anticipates 7-day demand horizons and algorithmically flags critical systemic vulnerabilities before they operationalize.
* **Key Metrics:** 7-Day Predicted Demand, Systemic Risk Score, Urgency Probability, Scarcity Index, and Total Predicted Deficit.
* **Core Visualizations:** Time-series line charts plotting the 7-day demand curve with shaded upper and lower statistical confidence intervals, a Risk vs. Efficiency diagnostic scatter plot for hospital evaluation, and an Actionable Triage Matrix isolating `🔴 Critical` clinical cases for immediate dispatch and resource allocation.
---

## 🗄️ Relational Data Model
The semantic model is structured in a Star Schema to optimize DAX query performance and seamlessly ingest the dynamic CSV outputs generated by the Python engine.

* **Fact Tables:**
  * `Fact_BloodInventory`: Central repository tracking baseline blood units.
  * `Fact_ML_Predictions`: Ingests the dynamically generated machine learning CSVs.
* **Dimension Tables:**
  * `Dim_Hospitals`: Attributes of regional healthcare facilities.
  * `Dim_Date`: Standard calendar table for time-intelligence calculations.
  * `Dim_BloodTypes`: Categorical classification of blood groups and Rh factors.

---

## 🎨 UI/UX Specifications
* **Design System:** Engineered utilizing a custom **Glassmorphism** framework to ensure a clean, modern, and cognitive-load-reducing environment.
* **Navigation:** Persistent, interactive left-pane navigation bar utilizing bookmarking and button triggers for seamless page transitions.

---

## ⚙️ Data Refresh Protocol
To maintain data fidelity and predictive accuracy, the dataset must be synchronized after running the predictive models:
1. Ensure `Predictive_Analytics_Pipeline.py` has been executed locally to generate the latest synthetic parameters.
2. Open `Project.pbix` in Microsoft Power BI Desktop.
3. Click **Refresh** in the Home ribbon to ingest the updated flat files.
