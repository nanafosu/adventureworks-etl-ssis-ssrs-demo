USE AdventureWorksDW_Custom;
UPDATE f
SET DateKey = CONVERT(INT, CONVERT(CHAR(8), f.OrderDate, 112))
FROM dw.FactSales AS f
WHERE f.DateKey IS NULL;
