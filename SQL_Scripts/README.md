# SQL Scripts Directory - Faseela Project

## Overview
This directory contains the Data Definition Language (DDL) and Data Manipulation Language (DML) scripts responsible for establishing the underlying relational database architecture for the Faseela predictive analytics pipeline. The scripts handle schema generation, entity relationship mapping, and the instantiation of a large-scale simulated clinical dataset.

## File Manifest

*   **`Blood_Shortage.sql`**
    The master SQL script that executes the complete database build and data population sequence. 

### Key Technical Operations

#### 1. Schema Architecture & Initialization
*   Initializes the `BloodShortage` database.
*   Constructs a star-schema foundation comprising dimensional tables (`Hospitals`, `Donors`, `Patients`, `DateDimension`) and a central fact table (`BloodStockForecast`).
*   Enforces relational integrity via Primary Key (PK) and Foreign Key (FK) constraints across all entities[cite: 5].

#### 2. Clinical Data Simulation
*   **Demographic Generation:** Generates 10,000 unique donor records and 20,000 patient records utilizing a randomized cross-join matrix of localized Arabic first and last names.
*   **Geolocation:** Populates the `Hospitals` table with precise latitude and longitude coordinates for major medical facilities across Egyptian governorates (e.g., Cairo, Giza, Alexandria, Assiut, Sohag).
*   **Fact Aggregation:** Dynamically populates the `BloodStockForecast` fact table by computing the aggregate sum of donated and required blood volumes per hospital and blood type.

#### 3. Statistical Distribution Enforcement
To ensure the machine learning models train on realistic variances, the script forces specific statistical distributions using `CHECKSUM(NEWID())` and `RAND()` logic:
*   **Donor Commitment:** Enforces a precise 20% commitment rate among the donor pool.
*   **Fulfillment Status:** Skews patient fulfillment to a 65% "Received" and 35% "Pending" ratio.
*   **Physiological Metrics:** Applies a clinical probability distribution to patient blood pressure levels: 70% Normal, 20% High, and 10% Low.

#### 4. Dimensional Modeling Refinements
*   Dynamically builds and populates a `DateDimension` table extracted from the forecast data, allowing for granular time-series analysis in downstream Business Intelligence tools.
*   Executes automated data cleansing and schema modification commands, ensuring bit flags are translated into descriptive categorical text (e.g., converting binary flags to 'Committed' or 'Not Committed') for optimized dashboard consumption.
