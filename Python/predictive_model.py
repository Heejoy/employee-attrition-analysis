import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression

df = pd.read_csv('Data/employee_attrition_cleaned.csv')

# ==========================================
# TRAIN THE BASELINE MODEL
# ==========================================
features = ['OverTime', 'MonthlyIncome', 'JobLevel']
x = df[features]
y = df['Attrition'] 

model = LogisticRegression(class_weight='balanced', max_iter=500)
model.fit(x, y)

# original baseline flight-risk probabilities (before strategy)
df['Current_Risk_Prob'] = model.predict_proba(x)[:, 1]

# ==========================================
# DEFINE TARGET
# ==========================================
target_criteria = (df['OverTime'] == 1) & (df['MonthlyIncome'] < 5000)
df['Is_High_Risk_Target'] = target_criteria

# ==========================================
# FINAL HR POLICY FUNCTIONS
# ==========================================
def apply_overtime_policy(row):
    if row['Is_High_Risk_Target'] and row['JobLevel'] in [1, 2]:
        return 0
    return row['OverTime']

def apply_salary_policy(row):
    if not row['Is_High_Risk_Target']:
        return row['MonthlyIncome']
        
    current_income = float(row['MonthlyIncome'])
    perf = row['PerformanceRating']
    invol = row['JobInvolvement']
    
    if perf == 4 and invol == 4:
        return current_income * 1.15
    if perf == 4 and invol == 3:
        return current_income * 1.10
        
    perf_multiplier = {1: 0.02, 2: 0.03, 3: 0.04, 4: 0.05}.get(perf, 0.0)
    return current_income * (1.0 + perf_multiplier)

# ==========================================
# APPLY STRATEGY & CALCULATE SCENARIO PROBABILITIES
# ==========================================
df_strategized = df.copy()

df_strategized['OverTime'] = df_strategized.apply(apply_overtime_policy, axis=1)
df_strategized['MonthlyIncome'] = df_strategized.apply(apply_salary_policy, axis=1)

x_strategized = df_strategized[features]
df['After_Risk_Prob'] = model.predict_proba(x_strategized)[:, 1]

# if probability is greater than 0.6, classify as attrition (1), else classify as retention (0)
df['Predicted_Attrition_Current'] = (df['Current_Risk_Prob'] >= 0.6).astype(int)
df['Predicted_Attrition_After'] = (df['After_Risk_Prob'] >= 0.6).astype(int)

# ==========================================
# EXPORT STRATEGIZED DATASET
# ==========================================
df_strategized['Current_Risk_Prob'] = df['Current_Risk_Prob']
df_strategized['After_Risk_Prob'] = df['After_Risk_Prob']
df_strategized['Predicted_Attrition_Current'] = df['Predicted_Attrition_Current']
df_strategized['Predicted_Attrition_After'] = df['Predicted_Attrition_After']

df_final = df_strategized.drop(columns=['Is_High_Risk_Target'])

df_final.to_csv("Data/attrition_predictions_result.csv", index=False)
