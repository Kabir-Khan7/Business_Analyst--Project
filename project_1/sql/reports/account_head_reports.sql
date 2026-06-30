USE fin_model;

USE fin_model;
GO

SELECT 
    d.Year AS Fiscal_Year,
    d.Month AS Fiscal_Month_Num,
    coa.Account_Name AS Account_Type,
    SUM(f.Amount) AS Total_Net_Amount
FROM 
    dbo.fct_subledger f
INNER JOIN 
    dbo.dim_chart_of_accounts coa ON f.GL_Account_Code = coa.GL_Account_Code
INNER JOIN 
    dbo.dim_date d ON f.DateKey = d.DateKey
GROUP BY 
    d.Year,
    d.Month,
    coa.Account_Name;


USE fin_model;
GO

-- Step 1: Define the temporary data layout using a CTE
WITH BaseData AS (
    SELECT 
        d.Year AS Fiscal_Year,
        d.Month AS Fiscal_Month_Num,
        coa.Account_Name AS Account_Type,
        f.Amount AS Transaction_Amount
    FROM 
        dbo.fct_subledger f
    INNER JOIN 
        dbo.dim_chart_of_accounts coa ON f.GL_Account_Code = coa.GL_Account_Code
    INNER JOIN 
        dbo.dim_date d ON f.DateKey = d.DateKey
    WHERE 
        d.Year = 2026 -- Filtering for a clean look at the current year
)
-- Step 2: Rotate the row metrics into monthly column headers
SELECT 
    Fiscal_Year,
    Account_Type,
    ISNULL([1], 0)  AS Jan,
    ISNULL([2], 0)  AS Feb,
    ISNULL([3], 0)  AS Mar,
    ISNULL([4], 0)  AS Apr,
    ISNULL([5], 0)  AS May,
    ISNULL([6], 0)  AS Jun,
    ISNULL([7], 0)  AS Jul,
    ISNULL([8], 0)  AS Aug,
    ISNULL([9], 0)  AS Sep,
    ISNULL([10], 0) AS Oct,
    ISNULL([11], 0) AS Nov,
    ISNULL([12], 0) AS "Dec"
FROM 
    BaseData
PIVOT (
    SUM(Transaction_Amount) 
    FOR Fiscal_Month_Num IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS PivotEngine;
GO