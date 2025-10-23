USE AdventureWorksDW_Custom;
GO
IF OBJECT_ID('dw.FactSales') IS NOT NULL DROP TABLE dw.FactSales;
GO

CREATE TABLE dw.FactSales
(
    FactSalesKey             BIGINT IDENTITY(1,1) PRIMARY KEY,
    SourceSalesOrderDetailID INT     NOT NULL,
    SalesOrderNumber         NVARCHAR(25) NULL,
    OrderDate                DATE        NULL,
    -- New: Int surrogate to DimDate (YYYYMMDD)
    DateKey                  INT         NULL,
    CustomerKey              INT         NULL,
    ProductKey               INT         NULL,
    OrderQty                 INT         NULL,
    UnitPrice                MONEY       NULL,
    SalesAmount AS (OrderQty * UnitPrice) PERSISTED
);
GO

-- Idempotence key
CREATE UNIQUE INDEX UX_FactSales_SourceLine
ON dw.FactSales (SourceSalesOrderDetailID);
GO

-- Helpful query indexes
CREATE INDEX IX_FactSales_OrderDate ON dw.FactSales (OrderDate);
CREATE INDEX IX_FactSales_DateKey   ON dw.FactSales (DateKey);
CREATE INDEX IX_FactSales_Customer  ON dw.FactSales (CustomerKey);
CREATE INDEX IX_FactSales_Product   ON dw.FactSales (ProductKey);
GO

-- FK to DimDate (add after DimDate is populated)
ALTER TABLE dw.FactSales  WITH NOCHECK
ADD CONSTRAINT FK_FactSales_DimDate
    FOREIGN KEY (DateKey) REFERENCES dw.DimDate(DateKey);
GO
