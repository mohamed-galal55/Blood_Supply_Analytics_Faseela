import sys
import subprocess

print("Forcing dependency installation and bypassing the environment lock...")
subprocess.check_call([sys.executable, '-m', 'pip', 'install', '--break-system-packages', 'pandas', 'openpyxl', 'numpy', 'scikit-learn', 'xgboost', 'prophet'])
print("Installation complete! Starting the pipeline...")
import pandas as pd
import numpy as np
import joblib

from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, accuracy_score
from xgboost import XGBRegressor, XGBClassifier
from prophet import Prophet

# =========================
# 📂 Load Data
# =========================
xls = pd.ExcelFile("Data_Model.xlsx")
print(xls.sheet_names)  # SEEING ALL SHEET NAMES




 # Reading All Sheets into a Dictionary
all_sheets = pd.read_excel(
    "Data_Model.xlsx",
    sheet_name=None
)

# Saving Each Sheet in a Dictionary for Easy Access
dataframes = {}

for sheet_name, df in all_sheets.items():
    dataframes[sheet_name] = df
    print(f"Sheet: {sheet_name}")
    print(df.head())
    print("-" * 50)

df_hospitals = dataframes["Dim_Hospitals"]
df_donors = dataframes["Dim_Donors"]
df_patients = dataframes["Dim_Patients"]
df_blood_type = dataframes["Dim_Blood_Types"]
df_forecast = dataframes["Dim_Blood_Forecast"]
# =========================
# 🧼 Cleaning
# =========================
df_forecast['fulfillment_rate'] = (
    df_forecast['fulfillment_rate']
    .astype(str)
    .str.replace('%', '', regex=False)
    .astype(float)
)

# =========================
# ⚙️ Feature Engineering
# =========================
df_forecast['coverage_ratio'] = df_forecast['total_donated'] / (df_forecast['total_required'] + 1e-6)
df_forecast['demand_pressure'] = df_forecast['total_required'] - df_forecast['total_donated']
df_forecast['risk_score'] = df_forecast['deficit'] / (df_forecast['total_required'] + 1e-6)
df_forecast['efficiency_score'] = df_forecast['total_donated'] / (df_forecast['deficit'] + 1e-6)
df_forecast['scarcity_index'] = df_forecast['deficit'] / (df_forecast['total_required'] + 1e-6)

features = [
    'total_donated',
    'total_required',
    'coverage_ratio',
    'demand_pressure',
    'risk_score',
    'fulfillment_rate',
    'efficiency_score',
    'scarcity_index'
]

X = df_forecast[features]
y_reg = df_forecast['deficit']
y_clf = df_forecast['urgency_level'].astype('category').cat.codes
print(y_reg.isna().mean() * 100)
# =========================
# 🔀 Train/Test Split
# =========================
X_train, X_test, y_reg_train, y_reg_test, y_clf_train, y_clf_test = train_test_split(
    X, y_reg, y_clf, test_size=0.2, random_state=42
)

# =========================
# 🔮 Regression Model (Deficit Prediction)
# =========================
reg_model = XGBRegressor(
    n_estimators=300,
    learning_rate=0.05,
    max_depth=5
)

print("X shape:", X_train.shape)
print("y_reg NaN:", y_reg_train.isna().sum())
print("y_reg min/max:", y_reg_train.min(), y_reg_train.max())

reg_model.fit(X_train, y_reg_train)
reg_pred = reg_model.predict(X_test)

print("📉 Regression MAE:", mean_absolute_error(y_reg_test, reg_pred))

# =========================
# 🚨 Classification Model (Urgency Level)
# =========================
clf_model = XGBClassifier(
    n_estimators=300,
    learning_rate=0.05,
    max_depth=5
)

clf_model.fit(X_train, y_clf_train)
clf_pred = clf_model.predict(X_test)

print("🎯 Classification Accuracy:", accuracy_score(y_clf_test, clf_pred))

# =========================
# 💾 Save Models (Production)
# =========================
joblib.dump(reg_model, "reg_model.pkl")
joblib.dump(clf_model, "clf_model.pkl")

# =========================
# 🚀 Full Prediction
# =========================
df_forecast['predicted_deficit'] = reg_model.predict(X)
df_forecast['urgency_prob'] = np.max(clf_model.predict_proba(X), axis=1)

# =========================
# 🧠 Smart Risk Engineering
# =========================
df_forecast['final_risk'] = (
    0.5 * (df_forecast['predicted_deficit'] / (df_forecast['total_required'] + 1e-6)) +
    0.3 * df_forecast['scarcity_index'] +
    0.2 * (1 - df_forecast['fulfillment_rate'] / 100)
)

high = df_forecast['final_risk'].quantile(0.75)
mid = df_forecast['final_risk'].quantile(0.45)

def status(x):
    if x > high:
        return "🔴 Critical"
    elif x > mid:
        return "🟡 Warning"
    return "🟢 Stable"

df_forecast['final_status'] = df_forecast['final_risk'].apply(status)

# =========================
# 🔁 Auto-Retraining (MLOPS)
# =========================
old_mae = float("inf")

try:
    old_model = joblib.load("reg_model.pkl")
    old_pred = old_model.predict(X_test)
    old_mae = mean_absolute_error(y_reg_test, old_pred)
except:
    pass

if mean_absolute_error(y_reg_test, reg_pred) < old_mae:
    joblib.dump(reg_model, "reg_model.pkl")
    print("✅ Model Updated (Better Performance)")
else:
    print("⚠️ Old Model Kept")


print("RAW SHAPE:", df_forecast.shape)
print(df_forecast[['forecast_date','total_required']].head(20))
print(df_forecast[['forecast_date','total_required']].isna().sum())
# =========================
# 📈 Time Series Prep
# =========================

ts = df_forecast.groupby('forecast_date')['total_required'].sum().reset_index()

ts.columns = ['ds', 'y']

print("TS shape:", ts.shape)
print(ts.head())
print("Shape:", ts.shape)
print("Missing values:\n", ts.isna().sum())

# 🚨 safety check
if len(ts) < 2:
    raise ValueError("❌ Not enough data for Prophet (need at least 2 rows)")

# =========================
# 🤖 Prophet Model
# =========================
prophet_model = Prophet()
prophet_model.fit(ts)

# =========================
# 🔮 7-Day Forecast
# =========================
future = prophet_model.make_future_dataframe(periods=7)
forecast = prophet_model.predict(future)

print("\n📅 7-Day Demand Forecast:")
print(forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].tail(7))
forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].to_csv(
    "demand_forecast_7days.csv",
    index=False,
    encoding="utf-8-sig"
)

print("✅ Saved: demand_forecast_7days.csv")

# =========================
# 🚨 Critical Cases
# =========================
print("\n===== CRITICAL CASES =====\n")

critical = df_forecast[df_forecast['final_status'] == "🔴 Critical"]

critical.to_csv("critical_cases.csv", index=False, encoding="utf-8-sig")
print("✅ Saved: critical_cases.csv")

for _, row in critical.iterrows():
    print(f"🚨 Hospital {row.get('hospital_id', 'N/A')} - {row.get('blood_type', 'N/A')}")
    print(f"Predicted Deficit: {row.get('predicted_deficit', 0):.1f}")
    print(f"Risk Score: {row.get('final_risk', 0):.3f}")
    print(f"Urgency Confidence: {row.get('urgency_prob', 0):.2f}")
    print("-" * 40)

print("\n✅ FINAL MLOPS + FORECASTING SYSTEM READY")  



df_forecast.to_csv("ai_forecast_results.csv", index=False, encoding="utf-8-sig")
print("✅ Saved: ai_forecast_results.csv") 