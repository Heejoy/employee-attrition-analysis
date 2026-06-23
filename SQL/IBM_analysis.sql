-- -----------------------------------------------------------------
-- Section 01 -- Company Historical KPIs
-- -----------------------------------------------------------------
-- 1) Total Employee Count, Actual Attrition, Baseline Attrition Rate
SELECT
    COUNT(*) AS total_employees,
    SUM(Attrition) AS total_attrition,
    ROUND(100.0 * SUM(Attrition) / COUNT(*), 2) AS attrition_rate
FROM attrition_predictions_result;

-- 2) Employees Working Overtime
SELECT 
    COUNT(*) AS total_who_left,
    SUM(CASE WHEN OverTime = 1 THEN 1 ELSE 0 END) AS left_and_worked_overtime,
    ROUND(100.0 * SUM(CASE WHEN OverTime = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_of_leavers_who_worked_overtime
FROM employee_attrition_cleaned
WHERE Attrition = 1;

-- 3) Junior(Job Level 1 & 2) Attrition among Total employees
SELECT 
    COUNT(*) AS total_who_left,
    SUM(CASE WHEN JobLevel IN (1, 2) THEN 1 ELSE 0 END) AS junior_exits,
    ROUND(
        100.0 * SUM(CASE WHEN JobLevel IN (1, 2) THEN 1 ELSE 0 END) 
        / COUNT(*), 2
    ) AS pct_of_leavers_who_are_junior
FROM employee_attrition_cleaned
WHERE Attrition = 1;

-- 4) Attrition among salary < $5,000
SELECT 
    COUNT(*) AS total_who_left,
    SUM(CASE WHEN MonthlyIncome < 5000 THEN 1 ELSE 0 END) AS low_salary_exits,
    ROUND(
        100.0 * SUM(CASE WHEN MonthlyIncome < 5000 THEN 1 ELSE 0 END) 
        / COUNT(*), 2
    ) AS pct_of_leavers_with_low_salary
FROM employee_attrition_cleaned
WHERE Attrition = 1;

-- -----------------------------------------------------------------
-- Section 02 -- Company Baseline KPIs
-- -----------------------------------------------------------------
-- (1) Attrition Rate
SELECT
    COUNT(*) AS total_employees,
    SUM(Predicted_Attrition_Current) AS predicted_total_attrition,
    ROUND(100.0 * SUM(Predicted_Attrition_Current) / COUNT(*), 2) AS predicted_attrition_rate
FROM attrition_predictions_result;

-- (2) Total Ovetime
SELECT 
    COUNT(*) AS total_overtime_employees,
    SUM(OverTime) AS overtime_count,
    ROUND(100.0 * SUM(OverTime) / COUNT(*), 2) AS overtime_rate
FROM employee_attrition_cleaned

-- (3) Junior's attrition rate
SELECT 
    COUNT(*) AS total_employees,                        
    SUM(CASE WHEN Predicted_Attrition_Current = 1 AND JobLevel IN (1, 2) THEN 1 ELSE 0 END) AS predicted_junior_exits, 
    ROUND(
        100.0 * SUM(CASE WHEN Predicted_Attrition_Current = 1 AND JobLevel IN (1, 2) THEN 1 ELSE 0 END) 
        / COUNT(*), 2
    ) AS predicted_junior_attrition_rate_of_total_employees                        
FROM attrition_predictions_result;

-- -----------------------------------------------------------------
-- Section 02 -- Company Baseline Results
-- -----------------------------------------------------------------
-- (1)  employee distribution by current risk tiers
SELECT 
    CASE    
        WHEN Current_Risk_Prob <= 0.30 THEN 'Low Risk (0-30%)'
        WHEN Current_Risk_Prob > 0.30 AND Current_Risk_Prob <= 0.50 THEN 'Medium Risk (31-50%)'
        ELSE 'High Risk (51-100%)'
    END AS current_risk_tier,
    COUNT(*) AS employee_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS employee_percentage
    
FROM attrition_predictions_result
GROUP BY 
    CASE    
        WHEN Current_Risk_Prob <= 0.30 THEN 'Low Risk (0-30%)'
        WHEN Current_Risk_Prob > 0.30 AND Current_Risk_Prob <= 0.50 THEN 'Medium Risk (31-50%)'
        ELSE 'High Risk (51-100%)'
    END
ORDER BY current_risk_tier;

-- (2) Baseline Attrition Breakdown within Overtime Status
SELECT 
    CASE WHEN A.OverTime = 1 THEN 'Overtime' ELSE 'Not Overtime' END AS overtime_status,
    
    SUM(CASE WHEN B.Predicted_Attrition_Current = 0 THEN 1 ELSE 0 END) AS predicted_stay_count,
    SUM(CASE WHEN B.Predicted_Attrition_Current = 1 THEN 1 ELSE 0 END) AS predicted_leave_count,
    COUNT(*) AS total_group_employees,
    
    ROUND(100.0 * SUM(CASE WHEN B.Predicted_Attrition_Current = 0 THEN 1 ELSE 0 END) / SUM(COUNT(*)) OVER(), 2) AS stay_percentage_of_total,
    ROUND(100.0 * SUM(CASE WHEN B.Predicted_Attrition_Current = 1 THEN 1 ELSE 0 END) / SUM(COUNT(*)) OVER(), 2) AS leave_percentage_of_total
    
FROM employee_attrition_cleaned A
INNER JOIN attrition_predictions_result B
    ON A.EmployeeNumber = B.EmployeeNumber
GROUP BY A.OverTime
ORDER BY A.OverTime ASC;

-- (3) Salary bracket attrition current baseline
WITH BaselineSalaryData AS (
    SELECT 
        CASE    
            WHEN MonthlyIncome < 5000 THEN '< $5k'
            WHEN MonthlyIncome >= 5000 AND MonthlyIncome < 10000 THEN '$5k-$10k'
            WHEN MonthlyIncome >= 10000 AND MonthlyIncome < 15000 THEN '$10k-$15k'
            ELSE '$15k-20k'
        END AS salary_bin,
        CASE WHEN Predicted_Attrition_Current = 1 THEN 'Leave' ELSE 'Stay' END AS employment_status,
        COUNT(*) AS employee_count,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM attrition_predictions_result), 2) AS percentage_of_total
    FROM attrition_predictions_result
    GROUP BY 
        CASE    
            WHEN MonthlyIncome < 5000 THEN '< $5k'
            WHEN MonthlyIncome >= 5000 AND MonthlyIncome < 10000 THEN '$5k-$10k'
            WHEN MonthlyIncome >= 10000 AND MonthlyIncome < 15000 THEN '$10k-$15k'
            ELSE '$15k-20k'
        END,
        Predicted_Attrition_Current
)
SELECT 
    salary_bin,
    employment_status,
    employee_count,
    percentage_of_total
FROM BaselineSalaryData
ORDER BY 
    CASE 
        WHEN salary_bin = '< $5k' THEN 1
        WHEN salary_bin = '$5k-$10k' THEN 2
        WHEN salary_bin = '$10k-$15k' THEN 3
        ELSE 4
    END, 
    CASE WHEN employment_status = 'Stay' THEN 1 ELSE 2 END ASC;

-- (4) Current risk probability (Junior vs. Senior)
WITH BaselineExperienceData AS (
    SELECT 
        CASE 
            WHEN JobLevel IN (1, 2) THEN 'Junior (JobLevel 1-2)'
            ELSE 'Mid-to-Senior (JobLevel 3-5)'
        END AS experience_tier,
        CASE WHEN Predicted_Attrition_Current = 1 THEN 'Leave' ELSE 'Stay' END AS employment_status,
        COUNT(*) AS employee_count,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM attrition_predictions_result), 2) AS percentage_of_total
    FROM attrition_predictions_result
    GROUP BY 
        CASE 
            WHEN JobLevel IN (1, 2) THEN 'Junior (JobLevel 1-2)'
            ELSE 'Mid-to-Senior (JobLevel 3-5)'
        END,
        Predicted_Attrition_Current
)
SELECT 
    experience_tier,
    employment_status,
    employee_count,
    percentage_of_total
FROM BaselineExperienceData
ORDER BY 
    CASE WHEN experience_tier = 'Junior (JobLevel 1-2)' THEN 1 ELSE 2 END ASC,
    CASE WHEN employment_status = 'Stay' THEN 1 ELSE 2 END ASC;

-- -----------------------------------------------------------------
-- Section 03 -- Post Strategy KPIs
-- -----------------------------------------------------------------
-- (1) Attrition Rate
SELECT
    COUNT(*) AS total_employees,
    SUM(Predicted_Attrition_After) AS predicted_total_attrition,
    ROUND(100.0 * SUM(Predicted_Attrition_After) / COUNT(*), 2) AS predicted_attrition_rate
FROM attrition_predictions_result;

-- (2) Total Overtime
SELECT 
    COUNT(*) AS total_overtime_employees,
    SUM(OverTime) AS overtime_count,
    ROUND(100.0 * SUM(OverTime) / COUNT(*), 2) AS overtime_rate
FROM attrition_predictions_result

-- (3) Junior's attrition rate
SELECT 
    COUNT(*) AS total_employees,                        
    SUM(CASE WHEN Predicted_Attrition_After = 1 AND JobLevel IN (1, 2) THEN 1 ELSE 0 END) AS predicted_junior_exits, 
    ROUND(
        100.0 * SUM(CASE WHEN Predicted_Attrition_After = 1 AND JobLevel IN (1, 2) THEN 1 ELSE 0 END) 
        / COUNT(*), 2
    ) AS predicted_junior_attrition_rate_of_total_employees                        
FROM attrition_predictions_result;

-- -----------------------------------------------------------------
-- Section 03 -- Company After Strategy Results
-- -----------------------------------------------------------------
-- (1)  employee distribution by current risk tiers
SELECT 
    CASE    
        WHEN After_Risk_Prob <= 0.30 THEN 'Low Risk (0-30%)'
        WHEN After_Risk_Prob > 0.30 AND After_Risk_Prob <= 0.50 THEN 'Medium Risk (31-50%)'
        ELSE 'High Risk (51-100%)'
    END AS after_risk_tier,
    COUNT(*) AS employee_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS employee_percentage
    
FROM attrition_predictions_result
GROUP BY 
    CASE    
        WHEN After_Risk_Prob <= 0.30 THEN 'Low Risk (0-30%)'
        WHEN After_Risk_Prob > 0.30 AND After_Risk_Prob <= 0.50 THEN 'Medium Risk (31-50%)'
        ELSE 'High Risk (51-100%)'
    END
ORDER BY after_risk_tier;

-- (2) Baseline Attrition Breakdown within Overtime Status
SELECT 
    CASE WHEN OverTime = 1 THEN 'Overtime' ELSE 'Not Overtime' END AS overtime_status,
    SUM(CASE WHEN Predicted_Attrition_After = 0 THEN 1 ELSE 0 END) AS predicted_stay_count,
    SUM(CASE WHEN Predicted_Attrition_After = 1 THEN 1 ELSE 0 END) AS predicted_leave_count,
    COUNT(*) AS total_group_employees,
    ROUND(100.0 * SUM(CASE WHEN Predicted_Attrition_After = 0 THEN 1 ELSE 0 END) / SUM(COUNT(*)) OVER(), 2) AS stay_percentage_of_total,
    ROUND(100.0 * SUM(CASE WHEN Predicted_Attrition_After = 1 THEN 1 ELSE 0 END) / SUM(COUNT(*)) OVER(), 2) AS leave_percentage_of_total

FROM attrition_predictions_result
GROUP BY OverTime
ORDER BY OverTime ASC; 

-- (3) Salary bracket attrition current baseline
WITH BaselineSalaryData AS (
    SELECT 
        CASE    
            WHEN MonthlyIncome < 5000 THEN '< $5k'
            WHEN MonthlyIncome >= 5000 AND MonthlyIncome < 10000 THEN '$5k-$10k'
            WHEN MonthlyIncome >= 10000 AND MonthlyIncome < 15000 THEN '$10k-$15k'
            ELSE '$15k-20k'
        END AS salary_bin,
        CASE WHEN Predicted_Attrition_After = 1 THEN 'Leave' ELSE 'Stay' END AS employment_status,
        COUNT(*) AS employee_count,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM attrition_predictions_result), 2) AS percentage_of_total
    FROM attrition_predictions_result
    GROUP BY 
        CASE    
            WHEN MonthlyIncome < 5000 THEN '< $5k'
            WHEN MonthlyIncome >= 5000 AND MonthlyIncome < 10000 THEN '$5k-$10k'
            WHEN MonthlyIncome >= 10000 AND MonthlyIncome < 15000 THEN '$10k-$15k'
            ELSE '$15k-20k'
        END,
        Predicted_Attrition_After
)
SELECT 
    salary_bin,
    employment_status,
    employee_count,
    percentage_of_total
FROM BaselineSalaryData
ORDER BY 
    CASE 
        WHEN salary_bin = '< $5k' THEN 1
        WHEN salary_bin = '$5k-$10k' THEN 2
        WHEN salary_bin = '$10k-$15k' THEN 3
        ELSE 4
    END, 
    CASE WHEN employment_status = 'Stay' THEN 1 ELSE 2 END ASC;

-- (4) After risk probability (Junior vs. Senior)
WITH BaselineExperienceData AS (
    SELECT 
        CASE 
            WHEN JobLevel IN (1, 2) THEN 'Junior (JobLevel 1-2)'
            ELSE 'Mid-to-Senior (JobLevel 3-5)'
        END AS experience_tier,
        CASE WHEN Predicted_Attrition_After = 1 THEN 'Leave' ELSE 'Stay' END AS employment_status,
        COUNT(*) AS employee_count,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM attrition_predictions_result), 2) AS percentage_of_total
    FROM attrition_predictions_result
    GROUP BY 
        CASE 
            WHEN JobLevel IN (1, 2) THEN 'Junior (JobLevel 1-2)'
            ELSE 'Mid-to-Senior (JobLevel 3-5)'
        END,
        Predicted_Attrition_After
)
SELECT 
    experience_tier,
    employment_status,
    employee_count,
    percentage_of_total
FROM BaselineExperienceData
ORDER BY 
    CASE WHEN experience_tier = 'Junior (JobLevel 1-2)' THEN 1 ELSE 2 END ASC,
    CASE WHEN employment_status = 'Stay' THEN 1 ELSE 2 END ASC;
