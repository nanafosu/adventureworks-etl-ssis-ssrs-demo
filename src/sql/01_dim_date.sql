USE AdventureWorksDW_Custom;
GO
IF SCHEMA_ID('dw') IS NULL EXEC('CREATE SCHEMA dw');
GO
IF OBJECT_ID('dw.DimDate') IS NOT NULL DROP TABLE dw.DimDate;
CREATE TABLE dw.DimDate(
    DateKey     INT PRIMARY KEY,
    FullDate    DATE,
    YearNumber  INT,
    MonthNumber INT,
    MonthName   VARCHAR(20),
    DayNumber   INT
);
