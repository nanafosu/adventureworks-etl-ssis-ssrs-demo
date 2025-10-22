-- Row counts
SELECT COUNT(*) AS FactSalesCount FROM dw.FactSales;

-- Top customers
SELECT TOP 10 d.FullName, SUM(f.SalesAmount) AS TotalSales
FROM dw.FactSales f
JOIN dw.DimCustomer d ON f.CustomerKey = d.CustomerKey
GROUP BY d.FullName
ORDER BY TotalSales DESC;
