-- ============================================================
--   PROCEDURE : usp_GenerateInvoice
--   DOMAIN    : Retail
--   PURPOSE   : Generates an invoice for a confirmed order
--   INPUT     : @OrderID    INT
--               @StateCode  VARCHAR(5)
--   OUTPUT    : @InvoiceID           INT
--               @InvoiceTotalWithTax DECIMAL(10,2)
--               @StatusMessage       VARCHAR(255)
--   CALLS     : fn_CalculateOrderTotal
--               fn_CalculateTax
--   TABLES    : Orders (READ + WRITE)
--               Invoices (WRITE)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.usp_GenerateInvoice', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GenerateInvoice;
GO

CREATE PROCEDURE usp_GenerateInvoice
(
    -- -------------------------------------------------------
    -- INPUT PARAMETERS
    -- -------------------------------------------------------
    @OrderID                INT,
    @StateCode              VARCHAR(5),

    -- -------------------------------------------------------
    -- OUTPUT PARAMETERS
    -- -------------------------------------------------------
    @InvoiceID              INT               OUTPUT,
    @InvoiceTotalWithTax    DECIMAL(10,2)     OUTPUT,
    @StatusMessage          VARCHAR(255)      OUTPUT
)
AS
BEGIN

    SET NOCOUNT ON;

    -- -------------------------------------------------------
    -- Step 1: Declare Local Variables
    -- -------------------------------------------------------
    DECLARE @OrderExists      INT;
    DECLARE @OrderStatus      VARCHAR(20);
    DECLARE @CustomerID       INT;
    DECLARE @SubTotal         DECIMAL(10,2);
    DECLARE @TaxAmount        DECIMAL(10,2);

    -- -------------------------------------------------------
    -- Step 2: Initialize Output Parameters
    -- -------------------------------------------------------
    SET @InvoiceID           = 0;
    SET @InvoiceTotalWithTax = 0.00;
    SET @StatusMessage       = '';

    -- -------------------------------------------------------
    -- VALIDATION 1: @StateCode must not be NULL or empty
    -- -------------------------------------------------------
    IF @StateCode IS NULL OR LTRIM(RTRIM(@StateCode)) = ''
    BEGIN
        SET @StatusMessage = 'ERROR: StateCode must not be NULL or empty.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 2: @OrderID must exist in Orders table
    -- -------------------------------------------------------
    SELECT
        @OrderExists = COUNT(1),
        @OrderStatus = MAX(Status),
        @CustomerID  = MAX(CustomerID)
    FROM Orders
    WHERE OrderID = @OrderID;

    IF @OrderExists = 0
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' does not exist in Orders table.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 3: Order Status must be 'Confirmed'
    --               Handle each invalid status explicitly
    -- -------------------------------------------------------
    IF @OrderStatus = 'Invoiced'
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' is already Invoiced.';
        RETURN;
    END

    IF @OrderStatus = 'Pending'
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' is still Pending. '
                           + 'Order must be Confirmed before invoicing.';
        RETURN;
    END

    IF @OrderStatus = 'Returned'
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' has been Returned. Cannot generate invoice.';
        RETURN;
    END

    IF @OrderStatus = 'Delivered'
    BEGIN
        SET @StatusMessage = 'ERROR: OrderID '
                           + CAST(@OrderID AS VARCHAR(10))
                           + ' is already Delivered. Cannot re-invoice.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- ALL VALIDATIONS PASSED — BEGIN TRANSACTION
    -- -------------------------------------------------------
    BEGIN TRANSACTION;

    BEGIN TRY

        -- ---------------------------------------------------
        -- Step 3: Call fn_CalculateOrderTotal
        --         Get SubTotal (after customer discount)
        -- ---------------------------------------------------
        SET @SubTotal = dbo.fn_CalculateOrderTotal(@OrderID);

        IF @SubTotal IS NULL OR @SubTotal = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @StatusMessage = 'ERROR: Could not calculate order total for OrderID '
                               + CAST(@OrderID AS VARCHAR(10));
            RETURN;
        END

        -- ---------------------------------------------------
        -- Step 4: Call fn_CalculateTax
        --         Compute tax on SubTotal by StateCode
        -- ---------------------------------------------------
        SET @TaxAmount = dbo.fn_CalculateTax(@SubTotal, @StateCode);

        -- ---------------------------------------------------
        -- Step 5: Compute Final Invoice Total
        --         InvoiceTotalWithTax = SubTotal + TaxAmount
        -- ---------------------------------------------------
        SET @InvoiceTotalWithTax = @SubTotal + @TaxAmount;

        -- ---------------------------------------------------
        -- Step 6: INSERT into Invoices table
        -- ---------------------------------------------------
        INSERT INTO Invoices
        (
            OrderID,
            InvoiceDate,
            SubTotal,
            TaxAmount,
            StateCode
        )
        VALUES
        (
            @OrderID,
            GETDATE(),
            @SubTotal,
            @TaxAmount,
            @StateCode
        );

        -- ---------------------------------------------------
        -- Step 7: Capture Generated InvoiceID
        -- ---------------------------------------------------
        SET @InvoiceID = SCOPE_IDENTITY();

        -- ---------------------------------------------------
        -- Step 8: UPDATE Orders Status to 'Invoiced'
        -- ---------------------------------------------------
        UPDATE Orders
        SET    Status = 'Invoiced'
        WHERE  OrderID = @OrderID;

        -- ---------------------------------------------------
        -- Step 9: COMMIT Transaction
        -- ---------------------------------------------------
        COMMIT TRANSACTION;

        -- ---------------------------------------------------
        -- Step 10: Set Success Message
        -- ---------------------------------------------------
        SET @StatusMessage = 'SUCCESS: Invoice generated successfully. '
                           + 'InvoiceID = '         + CAST(@InvoiceID            AS VARCHAR(10))
                           + ', SubTotal = '         + CAST(@SubTotal             AS VARCHAR(20))
                           + ', TaxAmount = '        + CAST(@TaxAmount            AS VARCHAR(20))
                           + ', TotalWithTax = '     + CAST(@InvoiceTotalWithTax  AS VARCHAR(20));

    END TRY

    BEGIN CATCH

        ROLLBACK TRANSACTION;

        SET @InvoiceID           = 0;
        SET @InvoiceTotalWithTax = 0.00;
        SET @StatusMessage       = 'ERROR: ' + ERROR_MESSAGE()
                                 + ' | Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));

    END CATCH;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
/*
DECLARE @InvoiceID INT, @InvoiceTotalWithTax DECIMAL(10,2), @StatusMessage VARCHAR(255);

-- Test 1: Valid Invoice — Order 1, StateCode TX (8.25%)
-- SubTotal = 66,500 | Tax = 5,486.25 | Total = 71,986.25
EXEC usp_GenerateInvoice 1, 'TX', @InvoiceID OUTPUT, @InvoiceTotalWithTax OUTPUT, @StatusMessage OUTPUT;
SELECT @InvoiceID AS InvoiceID, @InvoiceTotalWithTax AS TotalWithTax, @StatusMessage AS StatusMessage;
-- Expected: SUCCESS

-- Test 2: Already Invoiced
EXEC usp_GenerateInvoice 1, 'TX', @InvoiceID OUTPUT, @InvoiceTotalWithTax OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: OrderID 1 is already Invoiced.

-- Test 3: Non-Existing OrderID
EXEC usp_GenerateInvoice 9999, 'TX', @InvoiceID OUTPUT, @InvoiceTotalWithTax OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: OrderID 9999 does not exist.

-- Test 4: NULL StateCode
EXEC usp_GenerateInvoice 2, NULL, @InvoiceID OUTPUT, @InvoiceTotalWithTax OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: StateCode must not be NULL or empty.

-- Test 5: Empty StateCode
EXEC usp_GenerateInvoice 2, '', @InvoiceID OUTPUT, @InvoiceTotalWithTax OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: StateCode must not be NULL or empty.
*/
