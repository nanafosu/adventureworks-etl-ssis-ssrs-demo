USE AdventureWorksDW_Custom;
GO

IF OBJECT_ID('dw.DimDate', 'U') IS NOT NULL DROP TABLE dw.DimDate;
GO

CREATE TABLE dw.DimDate (
    DateKey          INT         NOT NULL PRIMARY KEY,   -- YYYYMMDD
    FullDate         DATE        NOT NULL,
    DayNumberOfWeek  TINYINT     NOT NULL,
    DayNameOfWeek    NVARCHAR(10) NOT NULL,
    DayNumberOfMonth TINYINT     NOT NULL,
    DayNumberOfYear  SMALLINT    NOT NULL,
    WeekNumberOfYear TINYINT     NOT NULL,
    MonthName        NVARCHAR(20) NOT NULL,
    MonthNumberOfYear TINYINT    NOT NULL,
    Quarter          TINYINT     NOT NULL,
    Year             SMALLINT    NOT NULL,
    IsWeekend        BIT         NOT NULL
);
GO
