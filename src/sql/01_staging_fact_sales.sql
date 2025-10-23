USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('stg.FactSales_Stage') IS NOT NULL DROP TABLE stg.FactSales_Stage;
CREATE TABLE stg.FactSales_Stage(
    SourceSalesOrderDetailID INT NOT NULL,
    SalesOrderNumber NVARCHAR(25),
    OrderDate DATE,
    CustomerKey INT,
    ProductKey INT,
    OrderQty INT,
    UnitPrice MONEY
);
GO
