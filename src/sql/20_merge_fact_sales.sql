USE AdventureWorksDW_Custom;

DECLARE @chg TABLE (ActionTaken NVARCHAR(10));

;WITH Src AS (
    SELECT
        SourceSalesOrderDetailID, SalesOrderNumber, OrderDate,
        -- Compute DateKey (YYYYMMDD) from OrderDate
        CONVERT(INT, CONVERT(CHAR(8), OrderDate, 112)) AS DateKey,
        CustomerKey, ProductKey, OrderQty, UnitPrice
    FROM stg.FactSales_Stage
)
MERGE dw.FactSales AS tgt
USING Src AS src
ON tgt.SourceSalesOrderDetailID = src.SourceSalesOrderDetailID

WHEN MATCHED AND (
       ISNULL(tgt.SalesOrderNumber,'') <> ISNULL(src.SalesOrderNumber,'')
    OR ISNULL(tgt.OrderDate,'1900-01-01') <> ISNULL(src.OrderDate,'1900-01-01')
    OR ISNULL(tgt.DateKey,0) <> ISNULL(src.DateKey,0)
    OR ISNULL(tgt.CustomerKey,-1) <> ISNULL(src.CustomerKey,-1)
    OR ISNULL(tgt.ProductKey ,-1) <> ISNULL(src.ProductKey ,-1)
    OR ISNULL(tgt.OrderQty   ,-1) <> ISNULL(src.OrderQty   ,-1)
    OR ISNULL(tgt.UnitPrice  , 0) <> ISNULL(src.UnitPrice  , 0)
)
THEN UPDATE SET
    tgt.SalesOrderNumber = src.SalesOrderNumber,
    tgt.OrderDate        = src.OrderDate,
    tgt.DateKey          = src.DateKey,
    tgt.CustomerKey      = src.CustomerKey,
    tgt.ProductKey       = src.ProductKey,
    tgt.OrderQty         = src.OrderQty,
    tgt.UnitPrice        = src.UnitPrice

WHEN NOT MATCHED BY TARGET THEN
    INSERT (SourceSalesOrderDetailID, SalesOrderNumber, OrderDate, DateKey,
            CustomerKey, ProductKey, OrderQty, UnitPrice)
    VALUES (src.SourceSalesOrderDetailID, src.SalesOrderNumber, src.OrderDate, src.DateKey,
            src.CustomerKey, src.ProductKey, src.OrderQty, src.UnitPrice)

OUTPUT $action INTO @chg(ActionTaken);

DECLARE @Inserted INT = (SELECT COUNT(*) FROM @chg WHERE ActionTaken='INSERT');
DECLARE @Updated  INT = (SELECT COUNT(*) FROM @chg WHERE ActionTaken='UPDATE');
DECLARE @Total    INT = @Inserted + @Updated;
RAISERROR('[MERGE COMPLETE] %d rows total (%d inserted, %d updated)', 10, 1, @Total, @Inserted, @Updated) WITH NOWAIT;

TRUNCATE TABLE stg.FactSales_Stage;
