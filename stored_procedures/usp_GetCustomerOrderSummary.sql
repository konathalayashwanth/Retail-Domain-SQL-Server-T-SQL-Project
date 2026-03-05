-- ============================================================
--   PROCEDURE : usp_GetCustomerOrderSummary
--   DOMAIN    : Retail
--   PURPOSE   : Returns order count and total spend for a
--               customer within a given date range
--   INPUT     : @CustomerID  INT
--               @FromDate    DATE
--               @ToDate      DATE
--   OUTPUT    : @TotalOrders    INT
--               @TotalSpent     DECIMAL(10,2)
--               @StatusMessage  VARCHAR(255)
--   CALLS     : fn_IsValidCustomer
--               fn_CalculateOrderTotal
--   TABLES    : Orders (READ)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.usp_GetCustomerOrderSummary', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetCustomerOrderSummary;
GO

CREATE PROCEDURE usp_GetCustomerOrderSummary
(
    -- -------------------------------------------------------
    -- INPUT PARAMETERS
    -- -------------------------------------------------------
    @CustomerID       INT,
    @FromDate         DATE,
    @ToDate           DATE,

    -- -------------------------------------------------------
    -- OUTPUT PARAMETERS
    -- -------------------------------------------------------
    @TotalOrders      INT              OUTPUT,
    @TotalSpent       DECIMAL(10,2)    OUTPUT,
    @StatusMessage    VARCHAR(255)     OUTPUT
)
AS
BEGIN

    SET NOCOUNT ON;

    -- -------------------------------------------------------
    -- Step 1: Declare Local Variables
    -- -------------------------------------------------------
    DECLARE @IsValidCustomer    BIT;
    DECLARE @DateDifference     INT;
    DECLARE @CurrentOrderID     INT;
    DECLARE @CurrentOrderTotal  DECIMAL(10,2);

    -- -------------------------------------------------------
    -- Step 2: Initialize Output Parameters
    -- -------------------------------------------------------
    SET @TotalOrders   = 0;
    SET @TotalSpent    = 0.00;
    SET @StatusMessage = '';

    -- -------------------------------------------------------
    -- VALIDATION 1: Call fn_IsValidCustomer
    --               Customer must be Active
    -- -------------------------------------------------------
    SET @IsValidCustomer = dbo.fn_IsValidCustomer(@CustomerID);

    IF @IsValidCustomer = 0
    BEGIN
        SET @StatusMessage = 'ERROR: Invalid or inactive customer. '
                           + 'CustomerID = '
                           + CAST(@CustomerID AS VARCHAR(10));
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 2: @FromDate and @ToDate must not be NULL
    -- -------------------------------------------------------
    IF @FromDate IS NULL OR @ToDate IS NULL
    BEGIN
        SET @StatusMessage = 'ERROR: FromDate and ToDate must not be NULL.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 3: @FromDate must be <= @ToDate
    -- -------------------------------------------------------
    IF @FromDate > @ToDate
    BEGIN
        SET @StatusMessage = 'ERROR: FromDate ('
                           + CAST(@FromDate AS VARCHAR(20))
                           + ') must be less than or equal to ToDate ('
                           + CAST(@ToDate   AS VARCHAR(20)) + ').';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 4: Date range must not exceed 365 days
    -- -------------------------------------------------------
    SET @DateDifference = DATEDIFF(DAY, @FromDate, @ToDate);

    IF @DateDifference > 365
    BEGIN
        SET @StatusMessage = 'ERROR: Date range exceeds 365 days. '
                           + 'Selected range = '
                           + CAST(@DateDifference AS VARCHAR(10))
                           + ' days. Allowed maximum is 365 days.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- ALL VALIDATIONS PASSED
    -- -------------------------------------------------------
    BEGIN TRY

        -- ---------------------------------------------------
        -- Step 3: Count Total Orders in the date range
        --         Exclude Returned orders from summary
        -- ---------------------------------------------------
        SELECT
            @TotalOrders = COUNT(1)
        FROM Orders
        WHERE CustomerID              = @CustomerID
        AND   CAST(OrderDate AS DATE) >= @FromDate
        AND   CAST(OrderDate AS DATE) <= @ToDate
        AND   Status                  != 'Returned';

        -- ---------------------------------------------------
        -- Step 4: Handle case when no orders found
        -- ---------------------------------------------------
        IF @TotalOrders = 0
        BEGIN
            SET @StatusMessage = 'INFO: No orders found for CustomerID '
                               + CAST(@CustomerID AS VARCHAR(10))
                               + ' between '
                               + CAST(@FromDate AS VARCHAR(20))
                               + ' and '
                               + CAST(@ToDate   AS VARCHAR(20)) + '.';
            RETURN;
        END

        -- ---------------------------------------------------
        -- Step 5: Loop through each Order using CURSOR
        --         Call fn_CalculateOrderTotal per Order
        --         Accumulate into @TotalSpent
        -- ---------------------------------------------------
        DECLARE OrderSummaryCursor CURSOR FOR
            SELECT OrderID
            FROM   Orders
            WHERE  CustomerID              = @CustomerID
            AND    CAST(OrderDate AS DATE) >= @FromDate
            AND    CAST(OrderDate AS DATE) <= @ToDate
            AND    Status                  != 'Returned';

        OPEN OrderSummaryCursor;

        FETCH NEXT FROM OrderSummaryCursor
        INTO @CurrentOrderID;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Call fn_CalculateOrderTotal for each order
            SET @CurrentOrderTotal = dbo.fn_CalculateOrderTotal(@CurrentOrderID);

            -- Accumulate total spent
            SET @TotalSpent = @TotalSpent + ISNULL(@CurrentOrderTotal, 0.00);

            FETCH NEXT FROM OrderSummaryCursor
            INTO @CurrentOrderID;
        END

        CLOSE OrderSummaryCursor;
        DEALLOCATE OrderSummaryCursor;

        -- ---------------------------------------------------
        -- Step 6: Set Success Message
        -- ---------------------------------------------------
        SET @StatusMessage = 'SUCCESS: Order summary generated. '
                           + 'CustomerID = '    + CAST(@CustomerID  AS VARCHAR(10))
                           + ', FromDate = '    + CAST(@FromDate    AS VARCHAR(20))
                           + ', ToDate = '      + CAST(@ToDate      AS VARCHAR(20))
                           + ', TotalOrders = ' + CAST(@TotalOrders AS VARCHAR(10))
                           + ', TotalSpent = '  + CAST(@TotalSpent  AS VARCHAR(20));

    END TRY

    BEGIN CATCH

        -- Close cursor if still open during error
        IF CURSOR_STATUS('global', 'OrderSummaryCursor') >= 0
        BEGIN
            CLOSE OrderSummaryCursor;
            DEALLOCATE OrderSummaryCursor;
        END

        SET @TotalOrders   = 0;
        SET @TotalSpent    = 0.00;
        SET @StatusMessage = 'ERROR: ' + ERROR_MESSAGE()
                           + ' | Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));

    END CATCH;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
/*
DECLARE @TotalOrders INT, @TotalSpent DECIMAL(10,2), @StatusMessage VARCHAR(255);

-- Test 1: Valid Summary — CustomerID 1 (Rajesh/Silver)
EXEC usp_GetCustomerOrderSummary 1, '2024-01-01', '2024-12-31',
     @TotalOrders OUTPUT, @TotalSpent OUTPUT, @StatusMessage OUTPUT;
SELECT @TotalOrders AS TotalOrders, @TotalSpent AS TotalSpent, @StatusMessage AS StatusMessage;
-- Expected: SUCCESS with order count and total

-- Test 2: FromDate > ToDate
EXEC usp_GetCustomerOrderSummary 1, '2024-12-31', '2024-01-01',
     @TotalOrders OUTPUT, @TotalSpent OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: FromDate must be <= ToDate.

-- Test 3: Date range > 365 days
EXEC usp_GetCustomerOrderSummary 1, '2023-01-01', '2024-12-31',
     @TotalOrders OUTPUT, @TotalSpent OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Date range exceeds 365 days.

-- Test 4: Invalid Customer
EXEC usp_GetCustomerOrderSummary 9999, '2024-01-01', '2024-12-31',
     @TotalOrders OUTPUT, @TotalSpent OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer.

-- Test 5: Inactive Customer
EXEC usp_GetCustomerOrderSummary 4, '2024-01-01', '2024-12-31',
     @TotalOrders OUTPUT, @TotalSpent OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer. (CustomerID 4 = Sneha/Inactive)
*/
