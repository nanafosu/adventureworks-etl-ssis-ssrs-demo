USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.FactSales') IS NOT NULL DROP TABLE dw.FactSales;
CREATE TABLE dw.FactSales(
    FactSalesKey     BIGINT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderNumber NVARCHAR(25),
    OrderDate        DATE,
    CustomerKey      INT,
    ProductKey       INT,
    OrderQty         INT,
    UnitPrice        MONEY,
    SalesAmount      AS (OrderQty * UnitPrice) PERSISTED
);
