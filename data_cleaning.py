import pandas as pd
 # read csv file
df = pd.read_csv('HR-Employee-Attrition.csv')
#print(df.head(5))

# Check the dataset
#print(df.columns)
#print(df.shape)
#print(df.info())

# Remove columns with no variance 
df = df.drop(columns=['EmployeeCount',
                      'Over18',
                      'StandardHours'])

#print(df.shape)

# Check unique value in categorical columns 
print(df['Attrition'].unique())
print(df['Gender'].unique())
print(df.nunique())

#Export the cleaned data 
df.to_csv("Cleaned-HR-Employee-Attrition.csv", index=False)