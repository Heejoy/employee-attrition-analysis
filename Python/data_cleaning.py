import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from statsmodels.stats.outliers_influence import variance_inflation_factor
import statsmodels.api as sm

# load the dataset
data = pd.read_csv('Data/employee_attrition.csv')

# clean uninformative columns 
columns_to_drop = [col for col in data.columns if data[col].nunique() == 1]
data = data.drop(columns=columns_to_drop)

# map text to numeric
data['Attrition'] = data['Attrition'].map({'Yes': 1, 'No': 0})
data['OverTime'] = data['OverTime'].map({'Yes': 1, 'No': 0})

categorical_cols = data.select_dtypes(include=['object']).columns.tolist()
data_encoded = pd.get_dummies(data, columns=categorical_cols, drop_first=False)

# core Correlations to Attrition 
correlations = data_encoded.corr()['Attrition'].abs().sort_values(ascending=False)
# exclude attriton itself from the list of correlations
top_10_correlations = correlations[1:11] 
print("--- Top 10 Correlations to Attrition ---")
print(top_10_correlations)

# =========================================================================
# FEATURE SELECTION
# =========================================================================
id_column = 'EmployeeNumber'
categorical_cols = [col for col in data.select_dtypes(include=['object']).columns if col != id_column]
data_encoded = pd.get_dummies(data, columns=categorical_cols, drop_first=False)

final_columns = [
    id_column,   
    'Attrition',            
    'TotalWorkingYears',    
    'OverTime',             
    'MonthlyIncome',        
    'JobLevel',              
    'PerformanceRating',     
    'JobInvolvement',        
]

# final dataframe for the model and strategy engine
data_final = data_encoded[final_columns].copy()
data_final[id_column] = data_final[id_column].astype(str) 
data_final['MonthlyIncome'] = data_final['MonthlyIncome'].astype(float)
data_final['JobLevel'] = data_final['JobLevel'].astype(int)
data_final['PerformanceRating'] = data_final['PerformanceRating'].astype(int)
data_final['JobInvolvement'] = data_final['JobInvolvement'].astype(int)

print("\n--- Final Optimized Project Variables Selected ---")
print(data_final.info())
print("\nData Shape:", data_final.shape)
print(data_final.head())

data_final.to_csv('Data/employee_attrition_cleaned.csv', index=False)
print("\n'Data/employee_attrition_cleaned.csv' updated with strategy columns.")
