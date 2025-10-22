USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.DimProduct') IS NOT NULL DROP TABLE dw.DimProduct;
CREATE TABLE dw.DimProduct(
    ProductKey           INT IDENTITY(1,1) PRIMARY KEY,
    ProductID            INT,
    EnglishProductName   NVARCHAR(200),
    ProductSubcategory   NVARCHAR(100),
    ProductCategory      NVARCHAR(100)
);
