USE fin_model;
GO

CREATE OR ALTER PROCEDURE sp_IngestRawData
    @FilePathA NVARCHAR(1000) = N'C:\Users\Admin\Desktop\DATA_ANALYSIS_PROJECT\project_1\data_collection\datasets\dataset_A.csv',
    @FilePathB NVARCHAR(1000) = N'C:\Users\Admin\Desktop\DATA_ANALYSIS_PROJECT\project_1\data_collection\datasets\dataset_B.csv',
    @FilePathC NVARCHAR(1000) = N'C:\Users\Admin\Desktop\DATA_ANALYSIS_PROJECT\project_1\data_collection\datasets\dataset_C.csv',
    @FilePathD NVARCHAR(1000) = N'C:\Users\Admin\Desktop\DATA_ANALYSIS_PROJECT\project_1\data_collection\datasets\dataset_D.csv',
    @FilePathE NVARCHAR(1000) = N'C:\Users\Admin\Desktop\DATA_ANALYSIS_PROJECT\project_1\data_collection\datasets\dataset_E.csv'
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
                            WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        -- 2. Ingest Bank Feed CSV
        PRINT 'Loading Bank Feed Data from: ' + @FilePathB;
        SET @DynamicSQL = N'BULK INSERT stg_bank_feed FROM ''' + @FilePathB + N''' 
                            WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        -- 3. Ingest Master Directory CSV
        PRINT 'Loading Master Directory Data from: ' + @FilePathC;
        SET @DynamicSQL = N'BULK INSERT stg_master_directory FROM ''' + @FilePathC + N''' 
                            WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        -- 4. Ingest Chart of Accounts CSV
        PRINT 'Loading Chart of Accounts Data from: ' + @FilePathD;
        SET @DynamicSQL = N'BULK INSERT stg_chart_of_accounts FROM ''' + @FilePathD + N''' 
                            WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        -- 5. Ingest Raw Invoices CSV
        PRINT 'Loading Raw Invoice Data from: ' + @FilePathE;
        SET @DynamicSQL = N'BULK INSERT stg_raw_invoices FROM ''' + @FilePathE + N''' 
                            WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', TABLOCK);';
        EXEC sp_executesql @DynamicSQL;

        PRINT 'ETL Pipeline Execution Complete!';
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
        PRINT 'ETL Pipeline Failed. Staging data state may be incomplete.';
    END CATCH
END;

-- Execute the Store Procedure
EXEC sp_IngestRawData;

--Check data in table
SELECT * FROM dbo.stg_subledger;
SELECT COUNT(*) FROM dbo.stg_subledger;