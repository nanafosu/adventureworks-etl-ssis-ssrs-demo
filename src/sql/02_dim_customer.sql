USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.DimCustomer') IS NOT NULL DROP TABLE dw.DimCustomer;
CREATE TABLE dw.DimCustomer(
    CustomerKey   INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID    INT,
    FullName      NVARCHAR(200),
    EmailAddress  NVARCHAR(200),
    Geography     NVARCHAR(100)
);