-- ============================================================
--   PROCEDURE : usp_PlaceOrder
--   DOMAIN    : Retail
--   PURPOSE   : Places a new order for a customer
--   INPUT     : @CustomerID  INT
--               @ProductID   INT
--               @Quantity    INT
--   OUTPUT    : @OrderID        INT
--               @TotalAmount    DECIMAL(10,2)
--               @StatusMessage  VARCHAR(255)
--   CALLS     : fn_IsValidCustomer
--               fn_GetAvailableStock
--               fn_GetCustomerDiscountRate
--               fn_CalculateOrderTotal
--   TABLES    : Products, Inventory (READ)
--               Orders, OrderItems, Inventory (WRITE)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.usp_PlaceOrder', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_PlaceOrder;
GO

CREATE PROCEDURE usp_PlaceOrder
(
    -- -------------------------------------------------------
    -- INPUT PARAMETERS
    -- -------------------------------------------------------
    @CustomerID      INT,
    @ProductID       INT,
    @Quantity        INT,

    -- -------------------------------------------------------
    -- OUTPUT PARAMETERS
    -- -------------------------------------------------------
    @OrderID         INT              OUTPUT,
    @TotalAmount     DECIMAL(10,2)    OUTPUT,
    @StatusMessage   VARCHAR(255)     OUTPUT
)
AS
BEGIN

    SET NOCOUNT ON;

    -- -------------------------------------------------------
    -- Step 1: Declare Local Variables
    -- -------------------------------------------------------
    DECLARE @IsValidCustomer    BIT;
    DECLARE @AvailableStock     INT;
    DECLARE @ProductExists      INT;
    DECLARE @UnitPrice          DECIMAL(10,2);
    DECLARE @DiscountRate       DECIMAL(5,2);
    DECLARE @LineTotal          DECIMAL(10,2);

    -- -------------------------------------------------------
    -- Step 2: Initialize Output Parameters
    -- -------------------------------------------------------
    SET @OrderID       = 0;
    SET @TotalAmount   = 0.00;
    SET @StatusMessage = '';

    -- -------------------------------------------------------
    -- VALIDATION 1: @Quantity must be greater than 0
    -- -------------------------------------------------------
    IF @Quantity <= 0
    BEGIN
        SET @StatusMessage = 'ERROR: Quantity must be greater than 0.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 2: @ProductID must exist in Products table
    --               and must be Active
    -- -------------------------------------------------------
    IF EXISTS
    (
        SELECT 1
        FROM   Products
        WHERE  ProductID = @ProductID
        AND    Status    = 'Active'
    )
    BEGIN
        SELECT
            @UnitPrice     = UnitPrice,
            @ProductExists = 1
        FROM Products
        WHERE ProductID = @ProductID
        AND   Status    = 'Active';
    END
    ELSE
    BEGIN
        SET @ProductExists = 0;
        SET @UnitPrice     = 0.00;
    END

    IF @ProductExists = 0
    BEGIN
        SET @StatusMessage = 'ERROR: ProductID '
                           + CAST(@ProductID AS VARCHAR(10))
                           + ' does not exist or is discontinued.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 3: Call fn_IsValidCustomer
    --               Returns 1 = Valid Active, 0 = Invalid
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
    -- VALIDATION 4: Call fn_GetAvailableStock
    --               Check if sufficient stock exists
    -- -------------------------------------------------------
    SET @AvailableStock = dbo.fn_GetAvailableStock(@ProductID);

    IF @AvailableStock < @Quantity
    BEGIN
        SET @StatusMessage = 'ERROR: Insufficient stock. '
                           + 'Requested = '  + CAST(@Quantity       AS VARCHAR(10))
                           + ', Available = ' + CAST(@AvailableStock AS VARCHAR(10));
        RETURN;
    END

    -- -------------------------------------------------------
    -- ALL VALIDATIONS PASSED — BEGIN TRANSACTION
    -- -------------------------------------------------------
    BEGIN TRANSACTION;

    BEGIN TRY

        -- ---------------------------------------------------
        -- Step 3: Call fn_GetCustomerDiscountRate
        --         Get discount % for this customer
        -- ---------------------------------------------------
        SET @DiscountRate = dbo.fn_GetCustomerDiscountRate(@CustomerID);

        -- ---------------------------------------------------
        -- Step 4: INSERT into Orders table
        -- ---------------------------------------------------
        INSERT INTO Orders
        (
            CustomerID,
            OrderDate,
            Status,
            TotalAmount,
            DiscountApplied
        )
        VALUES
        (
            @CustomerID,
            GETDATE(),
            'Confirmed',
            0.00,              -- Placeholder, updated after total calculation
            @DiscountRate      -- Discount % applied to this order
        );

        -- ---------------------------------------------------
        -- Step 5: Capture Generated OrderID
        -- ---------------------------------------------------
        SET @OrderID = SCOPE_IDENTITY();

        -- ---------------------------------------------------
        -- Step 6: Calculate LineTotal
        --         LineTotal = Quantity × UnitPrice
        -- ---------------------------------------------------
        SET @LineTotal = @Quantity * @UnitPrice;

        -- ---------------------------------------------------
        -- Step 7: INSERT into OrderItems table
        -- ---------------------------------------------------
        INSERT INTO OrderItems
        (
            OrderID,
            ProductID,
            Quantity,
            UnitPrice,
            LineTotal
        )
        VALUES
        (
            @OrderID,
            @ProductID,
            @Quantity,
            @UnitPrice,
            @LineTotal
        );

        -- ---------------------------------------------------
        -- Step 8: UPDATE Inventory — Decrement stock
        -- ---------------------------------------------------
        UPDATE Inventory
        SET
            AvailableQuantity = AvailableQuantity - @Quantity,
            LastUpdated       = GETDATE()
        WHERE ProductID = @ProductID;

        -- ---------------------------------------------------
        -- Step 9: Call fn_CalculateOrderTotal
        --         Compute final total after discount
        -- ---------------------------------------------------
        SET @TotalAmount = dbo.fn_CalculateOrderTotal(@OrderID);

        -- ---------------------------------------------------
        -- Step 10: UPDATE Orders with Final TotalAmount
        -- ---------------------------------------------------
        UPDATE Orders
        SET    TotalAmount = @TotalAmount
        WHERE  OrderID     = @OrderID;

        -- ---------------------------------------------------
        -- Step 11: COMMIT Transaction
        -- ---------------------------------------------------
        COMMIT TRANSACTION;

        -- ---------------------------------------------------
        -- Step 12: Set Success Message
        -- ---------------------------------------------------
        SET @StatusMessage = 'SUCCESS: Order placed successfully. '
                           + 'OrderID = '       + CAST(@OrderID     AS VARCHAR(10))
                           + ', TotalAmount = ' + CAST(@TotalAmount AS VARCHAR(20));

    END TRY

    BEGIN CATCH

        ROLLBACK TRANSACTION;

        SET @OrderID       = 0;
        SET @TotalAmount   = 0.00;
        SET @StatusMessage = 'ERROR: ' + ERROR_MESSAGE()
                           + ' | Line: '  + CAST(ERROR_LINE() AS VARCHAR(10));

    END CATCH;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
/*
DECLARE @OrderID INT, @TotalAmount DECIMAL(10,2), @StatusMessage VARCHAR(255);

-- Test 1: Valid order — Silver Customer
EXEC usp_PlaceOrder 1, 1, 2, @OrderID OUTPUT, @TotalAmount OUTPUT, @StatusMessage OUTPUT;
SELECT @OrderID AS OrderID, @TotalAmount AS TotalAmount, @StatusMessage AS StatusMessage;
-- Expected: SUCCESS, OrderID generated, TotalAmount = 95000.00 (100000 - 5%)

-- Test 2: Invalid Customer
EXEC usp_PlaceOrder 9999, 1, 1, @OrderID OUTPUT, @TotalAmount OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer.

-- Test 3: Insufficient Stock
EXEC usp_PlaceOrder 1, 1, 99999, @OrderID OUTPUT, @TotalAmount OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Insufficient stock.

-- Test 4: Invalid Quantity
EXEC usp_PlaceOrder 1, 1, 0, @OrderID OUTPUT, @TotalAmount OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Quantity must be greater than 0.

-- Test 5: Discontinued Product
EXEC usp_PlaceOrder 1, 12, 1, @OrderID OUTPUT, @TotalAmount OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Product does not exist or is discontinued.
*/
