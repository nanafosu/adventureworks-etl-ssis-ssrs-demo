USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.DimCustomer','U') IS NOT NULL DROP TABLE dw.DimCustomer;
GO

CREATE TABLE dw.DimCustomer(
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    FullName NVARCHAR(200),
    EmailAddress NVARCHAR(200),
    City NVARCHAR(100),
    Country NVARCHAR(100),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DimCustomer_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

CREATE UNIQUE INDEX UQ_DimCustomer_CustomerID ON dw.DimCustomer(CustomerID);
GO
