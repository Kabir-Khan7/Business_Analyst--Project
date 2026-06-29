-- Module 2: Data Warehouse & Transformation

IF OBJECT_ID('dbo.fct_subledger', 'U') IS NOT NULL DROP TABLE dbo.fct_subledger;
IF OBJECT_ID('dbo.fct_bank_feed', 'U') IS NOT NULL DROP TABLE dbo.fct_bank_feed;
IF OBJECT_ID('dbo.dim_entities', 'U') IS NOT NULL DROP TABLE dbo.dim_entities;
IF OBJECT_ID('dbo.dim_chart_of_accounts', 'U') IS NOT NULL DROP TABLE dbo.dim_chart_of_accounts;
IF OBJECT_ID('dbo.dim_date', 'U') IS NOT NULL DROP TABLE dbo.dim_date;

CREATE TABLE dim_chart_of_accounts (
    GL_Account_Code INT PRIMARY KEY,
    Account_Name VARCHAR(255) NOT NULL,
    Account_Class VARCHAR(100) NOT NULL,
    Financial_Statement_Section VARCHAR(255) NOT NULL
);

CREATE TABLE dim_entities (
    Entity_ID VARCHAR(50) PRIMARY KEY,
    Legal_Name VARCHAR(255) NOT NULL,
    Trade_Name VARCHAR(255) NULL,
    Tax_Registration_Number VARCHAR(100) NULL,
    Country_Code CHAR(2) NULL,
    Account_Creation_Date DATETIME2 NOT NULL,
    Is_Active BIT NOT NULL
);

CREATE TABLE dim_date (
    DateKey INT PRIMARY KEY, -- Format: YYYYMMDD
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(15) NOT NULL,
    Day INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(15) NOT NULL,
    IsWeekend BIT NOT NULL
);

CREATE TABLE fct_subledger (
    Transaction_ID UNIQUEIDENTIFIER PRIMARY KEY,
    System_Timestamp DATETIME2 NOT NULL,
    Document_Date DATETIME2 NOT NULL,
    DateKey INT NOT NULL, -- Core link to dim_date
    GL_Account_Code INT NOT NULL,
    Entity_ID VARCHAR(50) NULL, -- Kept nullable for manual ledger adjustments
    Amount DECIMAL(18, 2) NOT NULL,
    Transaction_Type VARCHAR(100) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Subledger_COA FOREIGN KEY (GL_Account_Code) REFERENCES dim_chart_of_accounts(GL_Account_Code),
    CONSTRAINT FK_Subledger_Entity FOREIGN KEY (Entity_ID) REFERENCES dim_entities(Entity_ID),
    CONSTRAINT FK_Subledger_Date FOREIGN KEY (DateKey) REFERENCES dim_date(DateKey)
);

CREATE TABLE fct_bank_feed (
    Bank_Row_ID INT PRIMARY KEY,
    Booking_Date DATETIME2 NOT NULL,
    Value_Date DATETIME2 NOT NULL,
    Booking_DateKey INT NOT NULL,
    Transaction_Text_Narrative NVARCHAR(MAX) NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    Running_Balance DECIMAL(18, 2) NOT NULL,
    CONSTRAINT FK_BankFeed_Date FOREIGN KEY (Booking_DateKey) REFERENCES dim_date(DateKey)
);
GO

-- 2. Populate the Date Dimension Table programmatically
DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2030-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO dim_date (DateKey, FullDate, Year, Quarter, Month, MonthName, Day, DayOfWeek, DayName, IsWeekend)
    VALUES (
        YEAR(@StartDate) * 10000 + MONTH(@StartDate) * 100 + DAY(@StartDate), -- YYYYMMDD
        @StartDate,
        YEAR(@StartDate),
        DATEPART(QUARTER, @StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DAY(@StartDate),
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1, 7) THEN 1 ELSE 0 END -- 1 = Sunday, 7 = Saturday
    );
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;
 
-------------------------------------------------------
-------------------------------------------------------

-- Step 1: Update the Ingestion Stored Procedure in SSMS 
USE fin_model;
GO

CREATE OR ALTER PROCEDURE sp_IngestRawData
    @FilePathA NVARCHAR(1000) = N'C:\\Users\\Admin\\Desktop\\DATA_ANALYSIS_PROJECT\\project_1\data_collection\\datasets\\dataset_A.csv',
    @FilePathB NVARCHAR(1000) = N'C:\\Users\\Admin\Desktop\\DATA_ANALYSIS_PROJECT\\project_1\\data_collection\\datasets\\dataset_B.csv',
    @FilePathC NVARCHAR(1000) = N'C:\\Users\\Admin\\Desktop\\DATA_ANALYSIS_PROJECT\\project_1\\data_collection\\datasets\\dataset_C.csv',
    @FilePathD NVARCHAR(1000) = N'C:\\Users\\Admin\\Desktop\\DATA_ANALYSIS_PROJECT\\project_1\\data_collection\\datasets\\dataset_D.csv',
    @FilePathE NVARCHAR(1000) = N'C:\\Users\\Admin\\Desktop\\DATA_ANALYSIS_PROJECT\\project_1\\data_collection\\datasets\\dataset_E.csv'
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear the Staging Tables to avoid appending duplicate records
    PRINT 'Truncating existing staging data layers...';
    TRUNCATE TABLE stg_subledger;
    TRUNCATE TABLE stg_bank_feed;
    TRUNCATE TABLE stg_master_directory;
    TRUNCATE TABLE stg_chart_of_accounts;
    TRUNCATE TABLE stg_raw_invoices;

    DECLARE @DynamicSQL NVARCHAR(MAX);

    BEGIN TRY
        -- 1. Ingest Subledger CSV
        PRINT 'Loading Subledger Data from: ' + @FilePathA;
        SET @DynamicSQL = N'BULK INSERT stg_subledger FROM ''' + @FilePathA + N''' 
                            WITH (FORMAT = ''CSV'', FIRSTROW = 2, TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        -- 2. Ingest Bank Feed CSV
        PRINT 'Loading Bank Feed Data from: ' + @FilePathB;
        SET @DynamicSQL = N'BULK INSERT stg_bank_feed FROM ''' + @FilePathB + N''' 
                            WITH (FORMAT = ''CSV'', FIRSTROW = 2, TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        -- 3. Ingest Master Directory CSV
        PRINT 'Loading Master Directory Data from: ' + @FilePathC;
        SET @DynamicSQL = N'BULK INSERT stg_master_directory FROM ''' + @FilePathC + N''' 
                            WITH (FORMAT = ''CSV'', FIRSTROW = 2, TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        -- 4. Ingest Chart of Accounts CSV
        PRINT 'Loading Chart of Accounts Data from: ' + @FilePathD;
        SET @DynamicSQL = N'BULK INSERT stg_chart_of_accounts FROM ''' + @FilePathD + N''' 
                            WITH (FORMAT = ''CSV'', FIRSTROW = 2, TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        -- 5. Ingest Raw Invoices CSV
        PRINT 'Loading Raw Invoice Data from: ' + @FilePathE;
        SET @DynamicSQL = N'BULK INSERT stg_raw_invoices FROM ''' + @FilePathE + N''' 
                            WITH (FORMAT = ''CSV'', FIRSTROW = 2, TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        PRINT 'ETL Pipeline Ingestion Complete with proper CSV handling!';
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
        PRINT 'ETL Pipeline Ingestion Failed.';
    END CATCH
END;
GO

-------------------------------------------------------
-------------------------------------------------------

--Step 2: Transforming Staging to Warehouse

USE fin_model;
GO

CREATE OR ALTER PROCEDURE sp_TransformStagingToWarehouse
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear production tables to ensure a clean reload execution
    PRINT 'Cleaning existing production data warehouse layers...';
    DELETE FROM fct_subledger;
    DELETE FROM fct_bank_feed;
    DELETE FROM dim_entities;
    DELETE FROM dim_chart_of_accounts;

    BEGIN TRY
        PRINT 'Transforming & Loading: dim_chart_of_accounts...';
        INSERT INTO dim_chart_of_accounts (GL_Account_Code, Account_Name, Account_Class, Financial_Statement_Section)
        SELECT 
            -- Fixed: Using clean, native T-SQL casting instead of REGEXP_REPLACE
            TRY_CAST(TRIM(GL_Account_Code) AS INT),
            TRIM(Account_Name),
            TRIM(Account_Class),
            TRIM(Financial_Statement_Section)
        FROM stg_chart_of_accounts
        WHERE NULLIF(TRIM(GL_Account_Code), '') IS NOT NULL;

        PRINT 'Transforming & Loading: dim_entities...';
        INSERT INTO dim_entities (Entity_ID, Legal_Name, Trade_Name, Tax_Registration_Number, Country_Code, Account_Creation_Date, Is_Active)
        SELECT 
            TRIM(Entity_ID),
            TRIM(Legal_Name),
            NULLIF(TRIM(Trade_Name), ''),
            NULLIF(TRIM(Tax_Registration_Number), ''),
            NULLIF(TRIM(Country_Code), ''),
            TRY_CAST(TRIM(Account_Creation_Date) AS DATETIME2),
            CASE WHEN TRIM(Is_Active) = 'True' THEN 1 ELSE 0 END
        FROM stg_master_directory
        WHERE NULLIF(TRIM(Entity_ID), '') IS NOT NULL;

        PRINT 'Transforming & Loading: fct_subledger...';
        INSERT INTO fct_subledger (Transaction_ID, System_Timestamp, Document_Date, DateKey, GL_Account_Code, Entity_ID, Amount, Transaction_Type, Status, Description)
        SELECT 
            TRY_CAST(TRIM(Transaction_ID) AS UNIQUEIDENTIFIER),
            TRY_CAST(TRIM(System_Timestamp) AS DATETIME2),
            TRY_CAST(TRIM(Document_Date) AS DATETIME2),
            -- Safely compute DateKey by extracting components from the parsed datetime
            YEAR(TRY_CAST(TRIM(Document_Date) AS DATETIME2)) * 10000 
            + MONTH(TRY_CAST(TRIM(Document_Date) AS DATETIME2)) * 100 
            + DAY(TRY_CAST(TRIM(Document_Date) AS DATETIME2)),
            TRY_CAST(TRIM(GL_Account_Code) AS INT),
            NULLIF(TRIM(Entity_ID), ''), 
            TRY_CAST(TRIM(Amount) AS DECIMAL(18, 2)),
            TRIM(Transaction_Type),
            TRIM(Status),
            NULLIF(REPLACE(TRIM(Description), CHAR(13), ''), '') -- Strip trailing carriage returns
        FROM stg_subledger
        WHERE NULLIF(TRIM(Transaction_ID), '') IS NOT NULL;

        PRINT 'Transforming & Loading: fct_bank_feed...';
        INSERT INTO fct_bank_feed (Bank_Row_ID, Booking_Date, Value_Date, Booking_DateKey, Transaction_Text_Narrative, Amount, Running_Balance)
        SELECT 
            TRY_CAST(TRIM(Bank_Row_ID) AS INT),
            TRY_CAST(TRIM(Booking_Date) AS DATETIME2),
            TRY_CAST(TRIM(Value_Date) AS DATETIME2),
            YEAR(TRY_CAST(TRIM(Booking_Date) AS DATETIME2)) * 10000 
            + MONTH(TRY_CAST(TRIM(Booking_Date) AS DATETIME2)) * 100 
            + DAY(TRY_CAST(TRIM(Booking_Date) AS DATETIME2)),
            TRIM(Transaction_Text_Narrative),
            TRY_CAST(TRIM(Amount) AS DECIMAL(18, 2)),
            -- Clean out the hidden trailing carriage returns (\r) from the last column before casting
            TRY_CAST(REPLACE(TRIM(Running_Balance), CHAR(13), '') AS DECIMAL(18, 2))
        FROM stg_bank_feed
        WHERE NULLIF(TRIM(Bank_Row_ID), '') IS NOT NULL;

        PRINT 'Warehouse Transformation Completed Successfully!';
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
        PRINT 'Warehouse Transformation Pipeline Failed.';
    END CATCH
END;
GO

-------------------------------------------------------
-------------------------------------------------------

-- 1. Reload the data into staging cleanly
EXEC sp_IngestRawData;

-- 2. Transform the clean staging data into the production warehouse tables
EXEC sp_TransformStagingToWarehouse;

-- Step 3: Audit Check 
SELECT COUNT(*) AS Production_BankFeed_Count FROM fct_bank_feed;

/*
The Big Picture 

[SOURCE FILES]              [STAGING LAYER]              [WAREHOUSE LAYER]
 Raw External Data          The "Forgiving" Landing Pad     The Hardened Star Schema
(Flat CSV Datasets)             (All VarChar Strings)         (Typed Dimensions & Facts)
 ┌───────────────┐               ┌───────────────────┐           ┌──────────────────────┐
 │ Subledger     │ ────────────> │ stg_subledger     │ ────────> │ fct_subledger        │
 ├───────────────┤               ├───────────────────┤           ├──────────────────────┤
 │ Bank Feed     │ ────────────> │ stg_bank_feed     │ ────────> │ fct_bank_feed        │
 ├───────────────┤    EXEC       ├───────────────────┤   EXEC    ├──────────────────────┤
 │ Master Direct.│ ────────────> │ stg_master_direct.│ ────────> │ dim_entities         │
 ├───────────────┤ sp_Ingest...  ├───────────────────┤ sp_Trans. ├──────────────────────┤
 │ Chart of Accts│               │ stg_chart_of_accts│ ────────> │ dim_chart_of_accounts│
 ├───────────────┤               ├───────────────────┤           ├──────────────────────┤
 │ Invoices (Raw)│               │ stg_raw_invoices  │           │ dim_date (Auto-Gen)  │
 └───────────────┘               └───────────────────┘           └──────────────────────┘

*/