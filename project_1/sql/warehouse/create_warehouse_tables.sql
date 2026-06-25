USE fin_model;
/*
We need to build your permanent, high-performance warehouse layer using a strict Star Schema design. This means creating:

Dimension Tables (dim_): To hold descriptive reference data (Entities, Chart of Accounts).

Fact Tables (fct_): To hold quantitative transaction measurements (Subledger entries, Bank feed rows).

Here is how these tables map together cleanly:

Plaintext
       ┌──────────────────────────┐          ┌──────────────────────────┐
       │   dim_chart_of_accounts  │          │       dim_entities       │
       └─────────────┬────────────┘          └─────────────┬────────────┘
                     │                                     │
                     │ (GL_Account_Code)                   │ (Entity_ID)
                     │                                     │
               ┌─────▼─────────────────────────────────────▼─────┐
               │                  fct_subledger                  │
               └─────────────────────────────────────────────────┘

*/


--Step 1: Create the Production Warehouse Tables (DDL)

-- 1. Core Dimension: Chart of Accounts
CREATE TABLE dim_chart_of_accounts (
    GL_Account_Code INT PRIMARY KEY,
    Account_Name VARCHAR(255) NOT NULL,
    Account_Class VARCHAR(100) NOT NULL,
    Financial_Statement_Section VARCHAR(255) NOT NULL
);

-- 2. Core Dimension: Master Directory (Entities)
CREATE TABLE dim_entities (
    Entity_ID VARCHAR(50) PRIMARY KEY,
    Legal_Name VARCHAR(255) NOT NULL,
    Trade_Name VARCHAR(255) NULL,
    Tax_Registration_Number VARCHAR(100) NULL,
    Country_Code CHAR(2) NULL,
    Account_Creation_Date DATETIME2 NOT NULL,
    Is_Active BIT NOT NULL
);

-- 3. Core Fact: ERP Subledger Transactions
CREATE TABLE fct_subledger (
    Transaction_ID UNIQUEIDENTIFIER PRIMARY KEY,
    System_Timestamp DATETIME2 NOT NULL,
    Document_Date DATETIME2 NOT NULL,
    GL_Account_Code INT NOT NULL,
    Entity_ID VARCHAR(50) NULL, -- Nullable for entries without assigned external entities
    Amount DECIMAL(18, 2) NOT NULL,
    Transaction_Type VARCHAR(100) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Subledger_COA FOREIGN KEY (GL_Account_Code) REFERENCES dim_chart_of_accounts(GL_Account_Code),
    CONSTRAINT FK_Subledger_Entity FOREIGN KEY (Entity_ID) REFERENCES dim_entities(Entity_ID)
);

-- 4. Core Fact: Bank Statement Feed
CREATE TABLE fct_bank_feed (
    Bank_Row_ID INT PRIMARY KEY,
    Booking_Date DATETIME2 NOT NULL,
    Value_Date DATETIME2 NOT NULL,
    Transaction_Text_Narrative NVARCHAR(MAX) NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    Running_Balance DECIMAL(18, 2) NOT NULL
);

