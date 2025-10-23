USE AdventureWorksDW_Custom;
GO
SET NOCOUNT ON;

TRUNCATE TABLE dw.DimDate;

DECLARE @StartDate DATE = '2010-01-01';
DECLARE @EndDate   DATE = '2030-12-31';

;WITH DateRange AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateRange
    WHERE DateValue < @EndDate
)
INSERT INTO dw.DimDate (
    DateKey, FullDate, DayNumberOfWeek, DayNameOfWeek,
    DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear,
    MonthName, MonthNumberOfYear, Quarter, Year, IsWeekend
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), DateValue, 112)) AS DateKey,
    DateValue AS FullDate,
    DATEPART(WEEKDAY, DateValue) AS DayNumberOfWeek,
    DATENAME(WEEKDAY, DateValue) AS DayNameOfWeek,
    DAY(DateValue) AS DayNumberOfMonth,
    DATEPART(DAYOFYEAR, DateValue) AS DayNumberOfYear,
    DATEPART(WEEK, DateValue) AS WeekNumberOfYear,
    DATENAME(MONTH, DateValue) AS MonthName,
    MONTH(DateValue) AS MonthNumberOfYear,
    DATEPART(QUARTER, DateValue) AS Quarter,
    YEAR(DateValue) AS Year,
    CASE WHEN DATENAME(WEEKDAY, DateValue) IN ('Saturday','Sunday') THEN 1 ELSE 0 END AS IsWeekend
FROM DateRange
OPTION (MAXRECURSION 0);
GO

-- Validate range
SELECT MIN(FullDate) AS MinDate, MAX(FullDate) AS MaxDate, COUNT(*) AS TotalRows FROM dw.DimDate;
