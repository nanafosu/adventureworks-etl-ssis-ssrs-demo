USE AdventureWorksDW_Custom;
GO

/* =========================
   1) Core row counts
   ========================= */
SELECT COUNT(*) AS FactSalesCount
FROM dw.FactSales;

-- Should always be 0 after a successful MERGE
SELECT COUNT(*) AS RowsInStage
FROM stg.FactSales_Stage;

/* =========================
   2) Top customers by sales
   ========================= */
SELECT TOP 10
    d.FullName,
    SUM(f.SalesAmount) AS TotalSales
FROM dw.FactSales f
JOIN dw.DimCustomer d ON f.CustomerKey = d.CustomerKey
GROUP BY d.FullName
ORDER BY TotalSales DESC;

/* =========================
   3) Duplicate-key guard
   (idempotence check)
   ========================= */
SELECT
    Duplicates = COUNT(*) - COUNT(DISTINCT f.SourceSalesOrderDetailID)
FROM dw.FactSales f;

/* =========================
   4) Referential integrity
   (keys in facts MUST exist in dims)
   ========================= */
SELECT
    MissingCustomers = SUM(CASE WHEN dc.CustomerKey IS NULL THEN 1 ELSE 0 END),
    MissingProducts  = SUM(CASE WHEN dp.ProductKey  IS NULL THEN 1 ELSE 0 END)
FROM dw.FactSales f
LEFT JOIN dw.DimCustomer dc ON f.CustomerKey = dc.CustomerKey
LEFT JOIN dw.DimProduct  dp ON f.ProductKey  = dp.ProductKey;

/* =========================
   5) Date sanity
   ========================= */
SELECT
    MinOrderDate = MIN(f.OrderDate),
    MaxOrderDate = MAX(f.OrderDate)
FROM dw.FactSales f;

/* =========================
   6) SalesAmount sanity
   (should equal OrderQty * UnitPrice)
   ========================= */
SELECT TOP 20
    f.SalesOrderNumber,
    f.OrderQty,
    f.UnitPrice,
    f.SalesAmount,
    Recalc = CAST(f.OrderQty * f.UnitPrice AS money)
FROM dw.FactSales f
WHERE f.SalesAmount <> CAST(f.OrderQty * f.UnitPrice AS money);

/* =========================
   7) Recent activity snapshot
   ========================= */
;WITH Recent AS (
    SELECT
        OrderDate,
        DaySales = SUM(SalesAmount)
    FROM dw.FactSales
    WHERE OrderDate >= DATEADD(DAY, -7, CAST(GETDATE() AS date))
    GROUP BY OrderDate
)
SELECT * FROM Recent ORDER BY OrderDate DESC

-- Orphan DateKeys (facts whose DateKey not in DimDate) - should be 0
SELECT OrphanDateKeys = COUNT(*)
FROM dw.FactSales f
LEFT JOIN dw.DimDate d ON f.DateKey = d.DateKey
WHERE d.DateKey IS NULL;

-- Quick sample of Fact joined to DimDate
SELECT TOP 10
    d.FullDate, d.MonthName, d.Year,
    SUM(f.SalesAmount) AS Sales
FROM dw.FactSales f
JOIN dw.DimDate d ON f.DateKey = d.DateKey
GROUP BY d.FullDate, d.MonthName, d.Year
ORDER BY d.FullDate DESC;

