-- AdventureWorks ETL + SSRS Project Structure

-- Folder: /src/ssis/AdventureWorksETL/
-- Contains all SSIS packages for data extraction, transformation, and loading.

-- Example: 02_Load_FactSales.dtsx handles the staging-to-dw load for FactSales.

-- SQL Scripts Overview

-- 01_dim_date.sql
USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.DimDate') IS NOT NULL DROP TABLE dw.DimDate;
CREATE TABLE dw.DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Quarter INT,
    Month INT,
    Day INT
);

-- 02_dim_customer.sql
USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.DimCustomer') IS NOT NULL DROP TABLE dw.DimCustomer;
CREATE TABLE dw.DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    FullName NVARCHAR(200)
);

-- 03_dim_product.sql
USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.DimProduct') IS NOT NULL DROP TABLE dw.DimProduct;
CREATE TABLE dw.DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    EnglishProductName NVARCHAR(200),
    ProductSubcategory NVARCHAR(100),
    ProductCategory NVARCHAR(100)
);

-- 10_fact_sales.sql
USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.FactSales') IS NOT NULL DROP TABLE dw.FactSales;
CREATE TABLE dw.FactSales (
    FactSalesKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderNumber NVARCHAR(25),
    OrderDate DATE,
    CustomerKey INT,
    ProductKey INT,
    OrderQty INT,
    UnitPrice MONEY,
    SalesAmount AS (OrderQty * UnitPrice) PERSISTED
);

-- MERGE_FactSales.sql
USE AdventureWorksDW_Custom;
SET XACT_ABORT ON;

BEGIN TRY
    DECLARE @chg TABLE (ActionTaken NVARCHAR(10));

    ;MERGE dw.FactSales AS tgt
    USING (
        SELECT SourceSalesOrderDetailID, SalesOrderNumber, OrderDate,
               CustomerKey, ProductKey, OrderQty, UnitPrice
        FROM stg.FactSales_Stage
    ) AS src
    ON tgt.SourceSalesOrderDetailID = src.SourceSalesOrderDetailID

    WHEN MATCHED AND (
           ISNULL(tgt.SalesOrderNumber,'') <> ISNULL(src.SalesOrderNumber,'')
        OR ISNULL(tgt.OrderDate, '1900-01-01') <> ISNULL(src.OrderDate, '1900-01-01')
        OR ISNULL(tgt.CustomerKey, -1) <> ISNULL(src.CustomerKey, -1)
        OR ISNULL(tgt.ProductKey , -1) <> ISNULL(src.ProductKey , -1)
        OR ISNULL(tgt.OrderQty   , -1) <> ISNULL(src.OrderQty   , -1)
        OR ISNULL(tgt.UnitPrice  , 0)  <> ISNULL(src.UnitPrice  , 0)
    ) THEN
        UPDATE SET
            tgt.SalesOrderNumber = src.SalesOrderNumber,
            tgt.OrderDate        = src.OrderDate,
            tgt.CustomerKey      = src.CustomerKey,
            tgt.ProductKey       = src.ProductKey,
            tgt.OrderQty         = src.OrderQty,
            tgt.UnitPrice        = src.UnitPrice

    WHEN NOT MATCHED BY TARGET THEN
        INSERT (SourceSalesOrderDetailID, SalesOrderNumber, OrderDate, CustomerKey, ProductKey, OrderQty, UnitPrice)
        VALUES (src.SourceSalesOrderDetailID, src.SalesOrderNumber, src.OrderDate, src.CustomerKey, src.ProductKey, src.OrderQty, src.UnitPrice)

    OUTPUT $action INTO @chg(ActionTaken);

    DECLARE @Inserted INT = (SELECT COUNT(*) FROM @chg WHERE ActionTaken = 'INSERT');
    DECLARE @Updated INT = (SELECT COUNT(*) FROM @chg WHERE ActionTaken = 'UPDATE');
    DECLARE @Total INT = @Inserted + @Updated;

    RAISERROR('[MERGE COMPLETE] %d rows total (%d inserted, %d updated)', 10, 1, @Total, @Inserted, @Updated) WITH NOWAIT;
    TRUNCATE TABLE stg.FactSales_Stage;
END TRY
BEGIN CATCH
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('[MERGE FAILED] %s', 16, 1, @msg);
    THROW;
END CATCH;

-- VALIDATION.SQL
SELECT COUNT(*) AS FactSalesCount FROM dw.FactSales;

SELECT TOP 10 d.FullName, SUM(f.SalesAmount) AS TotalSales
FROM dw.FactSales f
JOIN dw.DimCustomer d ON f.CustomerKey = d.CustomerKey
GROUP BY d.FullName
ORDER BY TotalSales DESC;

---

# SSRS Report Layer (Sales_Overview)

## 1) Shared Data Source
**Name:** `DS_AW_DW`  
**Type:** Microsoft SQL Server  
**Connection:** `Data Source=localhost;Initial Catalog=AdventureWorksDW_Custom`  
**Credentials:** Windows Authentication (same account used by SSIS) or stored SQL login with read access.

## 2) Shared Datasets
### A) `DS_Customers`
```sql
SELECT CustomerKey, FullName
FROM dw.DimCustomer
ORDER BY FullName;
```
### B) `DS_Categories`
```sql
SELECT DISTINCT ProductCategory
FROM dw.DimProduct
WHERE ProductCategory IS NOT NULL
ORDER BY ProductCategory;
```
### C) (Optional) `DS_SalesOverview`
Use only if you prefer a *shared* dataset. In most cases we keep the main dataset inside the report.

## 3) Report Parameters (report-level)
Create **four** parameters in this order:
1. `pStartDate` — *Date/Time*, **Allow null** ✓, **Available Values:** None, **Default:** `=DateSerial(2011,1,1)` (or none)
2. `pEndDate` — *Date/Time*, **Allow null** ✓, **Available Values:** None, **Default:** `=DateSerial(2014,12,31)` (or `=Today()`)
3. `pCustomerKey` — *Integer*, **Allow null** ✓, **Available Values:** from dataset `CustomersForRange` (see §4A) or `DS_Customers` if you do not cascade; **Default:** none (NULL)
4. `pCategory` — *Text*, **Allow null** ✓, **Available Values:** from `DS_Categories`; **Default:** none (NULL)

> **Tip:** Using NULL defaults enables the “All” behavior via the SQL `IS NULL` checks.

## 4) Report-level Datasets (inside the RDL)
### A) `CustomersForRange` (cascading Customer list)
Filters the Customer dropdown by the selected date range so users only see customers that actually have data.
```sql
SELECT DISTINCT c.CustomerKey, c.FullName
FROM dw.DimCustomer c
JOIN dw.FactSales f ON f.CustomerKey = c.CustomerKey
WHERE (@pStartDate IS NULL OR f.OrderDate >= @pStartDate)
  AND (@pEndDate   IS NULL OR f.OrderDate < DATEADD(DAY,1,@pEndDate))
ORDER BY c.FullName;
```
**Parameters tab:** map `@pStartDate` → `=Parameters!pStartDate.Value`, `@pEndDate` → `=Parameters!pEndDate.Value`.

> If you don’t want cascading behavior, set `pCustomerKey` to use `DS_Customers` instead.

### B) `SalesOverview` (main dataset)
```sql
SELECT
    d.FullName,
    p.ProductCategory,
    f.OrderDate,
    f.OrderQty,
    f.UnitPrice,
    f.SalesAmount
FROM dw.FactSales f
JOIN dw.DimCustomer d ON f.CustomerKey = d.CustomerKey
JOIN dw.DimProduct  p ON f.ProductKey  = p.ProductKey
WHERE (@pStartDate  IS NULL OR f.OrderDate >= @pStartDate)
  AND (@pEndDate    IS NULL OR f.OrderDate < DATEADD(DAY,1,@pEndDate))
  AND (@pCustomerKey IS NULL OR f.CustomerKey = @pCustomerKey)
  AND (NULLIF(@pCategory, '') IS NULL OR p.ProductCategory = @pCategory)
ORDER BY f.OrderDate, d.FullName;
```
**Dataset → Parameters tab (must map all 4):**  
`@pStartDate` = `=Parameters!pStartDate.Value`  
`@pEndDate`   = `=Parameters!pEndDate.Value`  
`@pCustomerKey` = `=Parameters!pCustomerKey.Value`  
`@pCategory`  = `=Parameters!pCategory.Value`

## 5) Build the Visuals
### A) Tablix (detail table)
Columns → `FullName`, `ProductCategory`, `OrderDate`, `OrderQty`, `UnitPrice`, `SalesAmount`.
- Format: `OrderDate` as Date; `UnitPrice` & `SalesAmount` as Currency.
- Bold header row, light gray background.

### B) Line Chart — *Total Sales Over Time*
- **Category Group:** `OrderDate`
- **Values:** `SUM(SalesAmount)`
- Format Y as Currency; X as Date (month or day), add title.

### C) Bar (or Pie) — *Sales by Product Category*
- **Category Group:** `ProductCategory`
- **Values:** `SUM(SalesAmount)`
- Show data labels (percent or value); add legend.

### D) KPI Textboxes (optional)
- Revenue: `=Sum(Fields!SalesAmount.Value, "SalesOverview")`
- Units: `=Sum(Fields!OrderQty.Value, "SalesOverview")`
- Orders: `=CountDistinct(Fields!SalesOrderNumber.Value, "SalesOverview")` *(include SalesOrderNumber in dataset if you need this KPI)*

## 6) Preview Scenarios
- **All:** leave Customer & Category as NULL, run with date window that matches your data (e.g., 2011–2014).
- **By Customer:** choose a Customer from `CustomersForRange` after setting dates.
- **By Category:** select a specific ProductCategory; combine with Customer for drill-like filtering.

## 7) Deployment (optional)
- Project → **Properties** → `TargetServerURL` = `http://localhost/ReportServer` (or your server).
- Build → Deploy.  Ensure the **shared data source** on the server uses credentials that can read `AdventureWorksDW_Custom`.

## 8) Troubleshooting Checklist
- **“One or more parameters not specified”** → A dataset param isn’t mapped to a report param; verify the 4 mappings in `SalesOverview`.
- **No rows returned** → Date window outside data range; try `2011-01-01` to `2014-12-31`. Ensure NULL-safe WHERE. Confirm table has **no extra Filters**.
- **Customer forces selection** → `pCustomerKey` must **Allow null** and Default = *None*; or use sentinel approach (`-1`) and adjust WHERE accordingly.
- **Dropdown empty** → The dataset for the dropdown can’t connect or fields aren’t refreshed. Ensure it uses `DS_AW_DW` and click **Refresh Fields**.
- **Design-time connection error** → Set `DS_AW_DW` to Windows Auth (Integrated) or provide a SQL login; **Test Connection**.

## 9) Versioning & Repro
- Commit `.rdl`, `.rsd`, `.rds` files under `/src/ssrs/AdventureWorksReports`.
- Commit screenshots of report output under `/docs/screenshots/` for portfolio use.
- Add `README.md` section with run steps: set data source, verify parameters, preview, deploy.

---

# README.md (copy/paste into repo root)

## AdventureWorks ETL + SSIS + SSRS Demo
End-to-end finance analytics demo using Microsoft data stack:
- **SQL Server**: custom DW schema (`AdventureWorksDW_Custom`)
- **SSIS**: stage + load pipeline (idempotent MERGE into `dw.FactSales`)
- **SSRS**: parameterized Sales Overview report (date range, customer, category)

---
## Repo Structure
```
adventureworks-etl-ssis-ssrs-demo/
├─ src/
│  ├─ sql/                 # All database DDL/DML & MERGE scripts
│  │  ├─ 01_dim_date.sql
│  │  ├─ 02_dim_customer.sql
│  │  ├─ 03_dim_product.sql
│  │  ├─ 10_fact_sales.sql
│  │  ├─ MERGE_FactSales.sql
│  │  └─ VALIDATION.sql
│  ├─ ssis/AdventureWorksETL/
│  │  └─ 02_Load_FactSales.dtsx
│  └─ ssrs/AdventureWorksReports/
│     ├─ Shared Data Sources/
│     │  └─ DS_AW_DW.rds
│     ├─ Shared Datasets/
│     │  ├─ DS_Customers.rsd
│     │  ├─ DS_Categories.rsd
│     │  └─ (optional) DS_SalesOverview.rsd
│     └─ Reports/
│        └─ Sales_Overview.rdl
├─ docs/
│  └─ screenshots/         # PNGs of SSIS and SSRS outputs
└─ README.md
```

---
## Prerequisites
- Windows 10/11
- **SQL Server 2019+** (Database Engine) + **SSMS**
- **SQL Server Integration Services** + **Visual Studio** with **SSIS** & **SSRS** extensions
- AdventureWorks OLTP/DW sample (or flat files used by package)

---
## 1) Database Setup
1. Create database:
   ```sql
   CREATE DATABASE AdventureWorksDW_Custom;
   ```
2. Run the DDL scripts in order:
   - `01_dim_date.sql`
   - `02_dim_customer.sql`
   - `03_dim_product.sql`
   - `10_fact_sales.sql`
3. (If needed) load dimension seed data from source (AdventureWorks) or your extracts.

---
## 2) SSIS Pipeline
- Open `src/ssis/AdventureWorksETL/AdventureWorksETL.sln` (or the project folder) in **Visual Studio**.
- Configure **Connection Managers**:
  - `CM_Source` → AdventureWorks source (or flat files)
  - `CM_DW` → `localhost`, `AdventureWorksDW_Custom`
- Data Flow (`02_Load_FactSales.dtsx`):
  - Staging → Lookups (Customer/Product) → OLE DB Dest: `stg.FactSales_Stage`
- Control Flow:
  - **Execute SQL Task** running `MERGE_FactSales.sql` (idempotent upsert) then `TRUNCATE stg.FactSales_Stage`.
- Run the package → expect console message like: `[MERGE COMPLETE] N rows total (X inserted, Y updated)`.

---
## 3) SSRS Report
- Open `src/ssrs/AdventureWorksReports/AdventureWorksReports.sln`.
- Shared Data Source: `DS_AW_DW` → `Data Source=localhost; Initial Catalog=AdventureWorksDW_Custom`.
- Report Parameters (in order): `pStartDate` (Date), `pEndDate` (Date), `pCustomerKey` (Int, null), `pCategory` (Text, null).
- Report datasets:
  - `CustomersForRange` (optional cascading): returns only customers with rows in selected date window.
  - `SalesOverview` (main dataset) with NULL-safe WHERE.
- Visuals: detail **Table**, **Line** (Sales over time), **Bar/Pie** (Sales by Category).
- **Preview** using date range `2011-01-01` → `2014-12-31`.

---
## 4) Validation
Run `src/sql/VALIDATION.sql`:
```sql
SELECT COUNT(*) AS FactSalesCount FROM dw.FactSales;
SELECT TOP 10 d.FullName, SUM(f.SalesAmount) TotalSales
FROM dw.FactSales f JOIN dw.DimCustomer d ON f.CustomerKey=d.CustomerKey
GROUP BY d.FullName ORDER BY TotalSales DESC;
```

---
## 5) Idempotency
The MERGE script ensures re-runs do **not** duplicate rows:
- Match on `SourceSalesOrderDetailID`
- Update changed fields
- Insert new, computed `SalesAmount` remains persisted via computed column
- Truncate stage after merge

---
## 6) Troubleshooting
- **No rows in report** → Expand date window (AW range ≈ 2011–2014). Ensure params allow NULL and mapping exists.
- **Param error** → Verify `SalesOverview` dataset has all 4 param mappings.
- **Login timeout** → Test `DS_AW_DW` connection. Use Windows Auth or a SQL login.
- **Lookup no match** in SSIS → Write no-match rows to a flat file (`C:\temp\MissingCustomers.txt`) to diagnose.

---
## 7) Resume/CAR Snippet
**AdventureWorks ETL & Reporting (SQL Server, SSIS, SSRS, Power BI-ready).** Built a parameterized sales analytics stack on a custom DW. **Context:** finance-style reporting over transactional
