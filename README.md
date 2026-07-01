# Blood Supply Analytics (Faseela)

<img width="2050" height="1280" alt="Executive_Overview" src="https://github.com/user-attachments/assets/22c37dcd-95df-493d-a75e-49350243319f" />

## 📌 Executive Summary
Faseela is a centralized, data-driven analytical reporting ecosystem engineered to monitor, analyze, and optimize regional blood supply chains. By dynamically aggregating data across local hospitals, registered donors, and regional blood banking facilities, the system establishes a continuous, transparent assessment of system-wide inventory health, logistical triage, and regional supply deficits.

---

## 🎯 Core Project Objectives
* **Deficit Identification:** Objectively pinpoint geographical and facility-level blood shortages across 27 governorates.
* **Supply Chain Optimization:** Model donor readiness indices against monthly patient demand metrics to mitigate inventory exhaustion.
* **Urgency Triage:** Track patient queues by multi-tier clinical urgency constraints to streamline medical dispatching.
* **Proactive Resource Allocation:** Evaluate historical transaction logs to predict systemic facility demand.

---

## 📊 Key Performance Indicators (KPIs)

### Overall Fulfillment Rate (OFR)
$$\text{Overall Fulfillment Rate} = \left( \frac{\text{Total Blood Units Supplied}}{\text{Total Blood Units Requested}} \right) \times 100$$

### Patient Fulfillment Rate (PFR)
$$\text{Patient Fulfillment Rate} = \left( \frac{\text{Fulfilled Patient Requests}}{\text{Total Patient Requests}} \right) \times 100$$

### Donor Readiness Rate (DRR)
$$\text{Donor Readiness Rate} = \left( \frac{\text{Eligible Active Donors}}{\text{Total Registered Donors}} \right) \times 100$$

---

## 🛠️ Technology Stack & Tool Pipeline
* **Data Generation:** Python (Custom scripts utilizing pandas and numpy to generate realistic, synthetic clinical data models).
* **Data Cleaning & Engineering:** SQL (DML/DDL scripts for constraint handling and normalization).
* **Semantic Modeling:** Microsoft Excel (Logic processing and primary staging validations).
* **High-Fidelity Visualization:** Microsoft Power BI Desktop (Pixel-perfect grid framework with glassmorphism UI/UX).

---

## ⚙️ Repository Folder Blueprint
* `/Data`: Container for baseline raw and processed datasets.
* `/Python_Scripts`: Algorithms engineered to generate the synthetic data environment.
* `/SQL_Scripts`: Source scripts tracking query execution transformations and schema layouts.
* `/PowerBI_Reports`: The master analytical visual dashboard (.pbix).

---

## 👥 The Development Team & Contributions
This data product was engineered, designed, and optimized synchronously by a 5-member project team:

| Team Member | Core Project Contribution | Technical Focus |
| :--- | :--- | :--- |
| **Ahmed Ali**|Orchestrated the project lifecycle and managed cross-functional workflows. Coordinated the integration of database architecture, machine learning outputs, and BI visualizations to ensure a cohesive, forward-thinking analytical product.|Project Manager & Team Lead
| **Mohamed Galal**|Engineered the visual hierarchy and user experience of the Power BI interface. Applied minimalist design principles to structure complex clinical data, ensuring intuitive navigation, reduced cognitive load, and optimal readability for decision-makers.|UI/UX Designer
| **Tasbeeh Zakaria**|Architected the foundational datasets. Executed the data generation, extraction, cleaning, and transformation processes to ensure high-fidelity, standardized inputs for both the SQL relational database and the Python predictive models.|Data Engineer
| **Ahmed Mansour**|Developed the predictive analytics pipeline (`Predictive_Analytics_Pipeline.py`). Implemented time-series forecasting using the Prophet library to predict 7-day hospital blood demand, and engineered the logic to flag high-risk shortage anomalies and critical patient cases.|Machine Learning Engineer
| **Michael Mina**|Constructed the Power BI operational dashboard. Integrated the underlying SQL data models and machine learning forecast outputs into interactive visual reports, enabling real-time monitoring of hospital KPIs, inventory deficits, and fulfillment rates.|BI Developer
