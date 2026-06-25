CREATE DATABASE fin_model;
use fin_model;

-- 1. Staging Subledger Table
CREATE TABLE stg_subledger (
    Transaction_ID VARCHAR(255),
    System_Timestamp VARCHAR(255),
    Document_Date VARCHAR(255),
    GL_Account_Code VARCHAR(50),
    Entity_ID VARCHAR(50),
    Amount VARCHAR(50),
    Transaction_Type VARCHAR(100),
    Status VARCHAR(50),
    Description VARCHAR(MAX)
);

-- 2. Staging Bank Feed Table
CREATE TABLE stg_bank_feed (
    Bank_Row_ID VARCHAR(50),
    Booking_Date VARCHAR(255),
    Value_Date VARCHAR(255),
    Transaction_Text_Narrative VARCHAR(MAX),
    Amount VARCHAR(50),
    Running_Balance VARCHAR(50)
);

-- 3. Staging Master Directory Table
CREATE TABLE stg_master_directory (
    Legal_Name VARCHAR(255),
    Trade_Name VARCHAR(255),
    Tax_Registration_Number VARCHAR(100),
    Country_Code VARCHAR(10),
    Account_Creation_Date VARCHAR(255),
    Is_Active VARCHAR(50),
    Entity_ID VARCHAR(50)
);

-- 4. Staging Chart of Accounts Table
CREATE TABLE stg_chart_of_accounts (
    GL_Account_Code VARCHAR(50),
    Account_Name VARCHAR(255),
    Account_Class VARCHAR(100),
    Financial_Statement_Section VARCHAR(255)
);

-- 5. Staging Raw Invoices Table (For the AI / PDF layer)
CREATE TABLE stg_raw_invoices (
    Vendor_ID VARCHAR(50),
    Vendor_Name VARCHAR(255),
    Invoice_Number VARCHAR(100),
    Invoice_Date VARCHAR(255),
    Line_Item_Description VARCHAR(MAX),
    Line_Item_Quantity VARCHAR(255),
    Line_Item_Unit_Price VARCHAR(255),
    Total_Tax VARCHAR(50),
    Grand_Total VARCHAR(50),
    Raw_Text VARCHAR(MAX)
);