USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.DimProduct','U') IS NOT NULL DROP TABLE dw.DimProduct;
GO

CREATE TABLE dw.DimProduct(
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    EnglishProductName NVARCHAR(200),
    ProductSubcategory NVARCHAR(100),
    ProductCategory NVARCHAR(100),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DimProduct_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

CREATE UNIQUE INDEX UQ_DimProduct_ProductID ON dw.DimProduct(ProductID);
GO
