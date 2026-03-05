-- ============================================================
--   PROCEDURE : usp_ProcessReturn
--   DOMAIN    : Retail
--   PURPOSE   : Processes a customer return request,
--               restores inventory, and calculates refund
--   INPUT     : @OrderID       INT
--               @CustomerID    INT
--               @ReturnReason  VARCHAR(255)
--   OUTPUT    : @RefundAmount   DECIMAL(10,2)
--               @ReturnID       INT
--               @StatusMessage  VARCHAR(255)
--   CALLS     : fn_IsValidCustomer
--               fn_CalculateOrderTotal
--   TABLES    : Orders (READ + WRITE)
--               OrderItems (READ)
--               Inventory (WRITE)
--               Returns (WRITE)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.usp_ProcessReturn', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ProcessReturn;
GO

CREATE PROCEDURE usp_ProcessReturn
(
    -- -------------------------------------------------------
    -- INPUT PARAMETERS
    -- -------------------------------------------------------
    @OrderID          INT,
    @CustomerID       INT,
    @ReturnReason     VARCHAR(255),

    -- -------------------------------------------------------
    -- OUTPUT PARAMETERS
    -- -------------------------------------------------------
    @RefundAmount     DECIMAL(10,2)    OUTPUT,
    @ReturnID         INT              OUTPUT,
    @StatusMessage    VARCHAR(255)     OUTPUT
)
AS
BEGIN

    SET NOCOUNT ON;

    -- -------------------------------------------------------
    -- Step 1: Declare Local Variables
    -- -------------------------------------------------------
    DECLARE @IsValidCustomer    BIT;
    DECLARE @OrderCustomerID    INT;
    DECLARE @OrderStatus        VARCHAR(20);
    DECLARE @OrderDate          DATETIME;
    DECLARE @DaysDifference     INT;
    DECLARE @RestoreProductID   INT;
    DECLARE @RestoreQuantity    INT;

    -- -------------------------------------------------------
    -- Step 2: Initialize Output Parameters
    -- -------------------------------------------------------
    SET @RefundAmount  = 0.00;
    SET @ReturnID      = 0;
    SET @StatusMessage = '';

    -- -------------------------------------------------------
    -- VALIDATION 1: @ReturnReason must not be NULL or Empty
    -- -------------------------------------------------------
    IF @ReturnReason IS NULL OR LTRIM(RTRIM(@ReturnReason)) = ''
    BEGIN
        SET @StatusMessage = 'ERROR: Return reason must not be NULL or empty.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 2: Call fn_IsValidCustomer
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
    -- VALIDATION 3: @OrderID must exist AND belong to customer
    -- -------------------------------------------------------
    SELECT
        @OrderCustomerID = CustomerID,
        @OrderStatus     = Status,
        @OrderDate       = OrderDate
    FROM Orders
    WHERE OrderID = @OrderID;

    -- Check if OrderID exists
    IF @OrderCustomerID IS NULL
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' does not exist.';
        RETURN;
    END

    -- Check if Order belongs to the given CustomerID
    IF @OrderCustomerID != @CustomerID
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' does not belong to CustomerID '
                           + CAST(@CustomerID AS VARCHAR(10));
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 4: Order must not already be 'Returned'
    -- -------------------------------------------------------
    IF @OrderStatus = 'Returned'
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' has already been Returned.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 5: Status must be 'Invoiced' or 'Delivered'
    -- -------------------------------------------------------
    IF @OrderStatus NOT IN ('Invoiced', 'Delivered')
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' cannot be returned. Current Status = '''
                           + @OrderStatus
                           + '''. Only Invoiced or Delivered orders can be returned.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 6: Return must be within 30 days of order
    -- -------------------------------------------------------
    SET @DaysDifference = DATEDIFF(DAY, @OrderDate, GETDATE());

    IF @DaysDifference > 30
    BEGIN
        SET @StatusMessage = 'ERROR: Return period has expired. '
                           + 'Order was placed '
                           + CAST(@DaysDifference AS VARCHAR(10))
                           + ' days ago. Returns allowed within 30 days only.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- ALL VALIDATIONS PASSED — BEGIN TRANSACTION
    -- -------------------------------------------------------
    BEGIN TRANSACTION;

    BEGIN TRY

        -- ---------------------------------------------------
        -- Step 3: Call fn_CalculateOrderTotal
        --         Compute Refund Amount (order total)
        -- ---------------------------------------------------
        SET @RefundAmount = dbo.fn_CalculateOrderTotal(@OrderID);

        -- ---------------------------------------------------
        -- Step 4: INSERT into Returns table
        -- ---------------------------------------------------
        INSERT INTO Returns
        (
            OrderID,
            CustomerID,
            ReturnDate,
            ReturnReason,
            RefundAmount,
            Status
        )
        VALUES
        (
            @OrderID,
            @CustomerID,
            GETDATE(),
            @ReturnReason,
            @RefundAmount,
            'Processed'
        );

        -- ---------------------------------------------------
        -- Step 5: Capture Generated ReturnID
        -- ---------------------------------------------------
        SET @ReturnID = SCOPE_IDENTITY();

        -- ---------------------------------------------------
        -- Step 6: Restore Stock using CURSOR
        --         Loop through all OrderItems for this order
        --         Increment inventory for each product
        -- ---------------------------------------------------
        DECLARE RestoreCursor CURSOR FOR
            SELECT ProductID, Quantity
            FROM   OrderItems
            WHERE  OrderID = @OrderID;

        OPEN RestoreCursor;

        FETCH NEXT FROM RestoreCursor
        INTO @RestoreProductID, @RestoreQuantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE Inventory
            SET
                AvailableQuantity = AvailableQuantity + @RestoreQuantity,
                LastUpdated       = GETDATE()
            WHERE ProductID = @RestoreProductID;

            FETCH NEXT FROM RestoreCursor
            INTO @RestoreProductID, @RestoreQuantity;
        END

        CLOSE RestoreCursor;
        DEALLOCATE RestoreCursor;

        -- ---------------------------------------------------
        -- Step 7: UPDATE Orders Status to 'Returned'
        -- ---------------------------------------------------
        UPDATE Orders
        SET    Status = 'Returned'
        WHERE  OrderID = @OrderID;

        -- ---------------------------------------------------
        -- Step 8: COMMIT Transaction
        -- ---------------------------------------------------
        COMMIT TRANSACTION;

        -- ---------------------------------------------------
        -- Step 9: Set Success Message
        -- ---------------------------------------------------
        SET @StatusMessage = 'SUCCESS: Return processed successfully. '
                           + 'ReturnID = '       + CAST(@ReturnID     AS VARCHAR(10))
                           + ', RefundAmount = ' + CAST(@RefundAmount AS VARCHAR(20));

    END TRY

    BEGIN CATCH

        -- Close and deallocate cursor if still open on error
        IF CURSOR_STATUS('global', 'RestoreCursor') >= 0
        BEGIN
            CLOSE RestoreCursor;
            DEALLOCATE RestoreCursor;
        END

        ROLLBACK TRANSACTION;

        SET @RefundAmount  = 0.00;
        SET @ReturnID      = 0;
        SET @StatusMessage = 'ERROR: ' + ERROR_MESSAGE()
                           + ' | Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));

    END CATCH;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
/*
DECLARE @RefundAmount DECIMAL(10,2), @ReturnID INT, @StatusMessage VARCHAR(255);

-- Test 1: Valid Return — Order must be Invoiced/Delivered first
EXEC usp_ProcessReturn 1, 1, 'Product damaged on arrival',
     @RefundAmount OUTPUT, @ReturnID OUTPUT, @StatusMessage OUTPUT;
SELECT @ReturnID AS ReturnID, @RefundAmount AS RefundAmount, @StatusMessage AS StatusMessage;
-- Expected: SUCCESS

-- Test 2: Already Returned
EXEC usp_ProcessReturn 1, 1, 'Trying again',
     @RefundAmount OUTPUT, @ReturnID OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: OrderID 1 has already been Returned.

-- Test 3: Invalid Customer
EXEC usp_ProcessReturn 2, 9999, 'Defective product',
     @RefundAmount OUTPUT, @ReturnID OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer.

-- Test 4: NULL ReturnReason
EXEC usp_ProcessReturn 2, 2, NULL,
     @RefundAmount OUTPUT, @ReturnID OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Return reason must not be NULL or empty.

-- Test 5: Order does not belong to customer
EXEC usp_ProcessReturn 2, 1, 'Wrong customer',
     @RefundAmount OUTPUT, @ReturnID OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: OrderID 2 does not belong to CustomerID 1.
*/
