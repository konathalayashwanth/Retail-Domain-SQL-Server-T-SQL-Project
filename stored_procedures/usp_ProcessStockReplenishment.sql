-- ============================================================
--   PROCEDURE : usp_ProcessStockReplenishment
--   DOMAIN    : Retail
--   PURPOSE   : Restocks product inventory from an authorized
--               supplier and records a purchase order
--   INPUT     : @ProductID         INT
--               @SupplierID        INT
--               @QuantityReceived  INT
--   OUTPUT    : @PurchaseOrderID   INT
--               @UpdatedStockLevel INT
--               @StatusMessage     VARCHAR(255)
--   CALLS     : fn_GetAvailableStock
--               fn_GetProductCategory
--   TABLES    : Products, Suppliers, SupplierCategories,
--               Categories (READ)
--               PurchaseOrders, Inventory (WRITE)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.usp_ProcessStockReplenishment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ProcessStockReplenishment;
GO

CREATE PROCEDURE usp_ProcessStockReplenishment
(
    -- -------------------------------------------------------
    -- INPUT PARAMETERS
    -- -------------------------------------------------------
    @ProductID          INT,
    @SupplierID         INT,
    @QuantityReceived   INT,

    -- -------------------------------------------------------
    -- OUTPUT PARAMETERS
    -- -------------------------------------------------------
    @PurchaseOrderID    INT              OUTPUT,
    @UpdatedStockLevel  INT              OUTPUT,
    @StatusMessage      VARCHAR(255)     OUTPUT
)
AS
BEGIN

    SET NOCOUNT ON;

    -- -------------------------------------------------------
    -- Step 1: Declare Local Variables
    -- -------------------------------------------------------
    DECLARE @ProductExists      INT;
    DECLARE @SupplierExists     INT;
    DECLARE @SupplierStatus     VARCHAR(20);
    DECLARE @CategoryName       VARCHAR(50);
    DECLARE @IsAuthorized       INT;
    DECLARE @CurrentStock       INT;

    -- -------------------------------------------------------
    -- Step 2: Initialize Output Parameters
    -- -------------------------------------------------------
    SET @PurchaseOrderID   = 0;
    SET @UpdatedStockLevel = 0;
    SET @StatusMessage     = '';

    -- -------------------------------------------------------
    -- VALIDATION 1: @QuantityReceived must be greater than 0
    -- -------------------------------------------------------
    IF @QuantityReceived <= 0
    BEGIN
        SET @StatusMessage = 'ERROR: QuantityReceived must be greater than 0.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 2: @ProductID must exist and be Active
    -- -------------------------------------------------------
    SELECT
        @ProductExists = COUNT(1)
    FROM Products
    WHERE ProductID = @ProductID
    AND   Status    = 'Active';

    IF @ProductExists = 0
    BEGIN
        SET @StatusMessage = 'ERROR: ProductID '
                           + CAST(@ProductID AS VARCHAR(10))
                           + ' does not exist or is discontinued.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 3: @SupplierID must exist and be Active
    -- -------------------------------------------------------
    SELECT
        @SupplierExists = COUNT(1),
        @SupplierStatus = MAX(Status)
    FROM Suppliers
    WHERE SupplierID = @SupplierID;

    IF @SupplierExists = 0
    BEGIN
        SET @StatusMessage = 'ERROR: SupplierID '
                           + CAST(@SupplierID AS VARCHAR(10))
                           + ' does not exist.';
        RETURN;
    END

    IF @SupplierStatus != 'Active'
    BEGIN
        SET @StatusMessage = 'ERROR: SupplierID '
                           + CAST(@SupplierID AS VARCHAR(10))
                           + ' is not Active.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 4: Call fn_GetProductCategory
    --               Get Category of the Product
    -- -------------------------------------------------------
    SET @CategoryName = dbo.fn_GetProductCategory(@ProductID);

    IF @CategoryName IS NULL
    BEGIN
        SET @StatusMessage = 'ERROR: Could not determine category for ProductID '
                           + CAST(@ProductID AS VARCHAR(10));
        RETURN;
    END

    -- -------------------------------------------------------
    -- VALIDATION 5: Supplier must be authorized for
    --               the Product's Category
    -- -------------------------------------------------------
    SELECT
        @IsAuthorized = COUNT(1)
    FROM SupplierCategories SC
    INNER JOIN Categories C
        ON  SC.CategoryID = C.CategoryID
    WHERE SC.SupplierID   = @SupplierID
    AND   C.CategoryName  = @CategoryName;

    IF @IsAuthorized = 0
    BEGIN
        SET @StatusMessage = 'ERROR: SupplierID '
                           + CAST(@SupplierID AS VARCHAR(10))
                           + ' is not authorized to supply '
                           + 'category: ''' + @CategoryName + '''.';
        RETURN;
    END

    -- -------------------------------------------------------
    -- ALL VALIDATIONS PASSED — BEGIN TRANSACTION
    -- -------------------------------------------------------
    BEGIN TRANSACTION;

    BEGIN TRY

        -- ---------------------------------------------------
        -- Step 3: Call fn_GetAvailableStock
        --         Capture current stock before update
        -- ---------------------------------------------------
        SET @CurrentStock = dbo.fn_GetAvailableStock(@ProductID);

        -- ---------------------------------------------------
        -- Step 4: INSERT into PurchaseOrders table
        -- ---------------------------------------------------
        INSERT INTO PurchaseOrders
        (
            ProductID,
            SupplierID,
            QuantityReceived,
            PurchaseDate,
            Status
        )
        VALUES
        (
            @ProductID,
            @SupplierID,
            @QuantityReceived,
            GETDATE(),
            'Received'
        );

        -- ---------------------------------------------------
        -- Step 5: Capture Generated PurchaseOrderID
        -- ---------------------------------------------------
        SET @PurchaseOrderID = SCOPE_IDENTITY();

        -- ---------------------------------------------------
        -- Step 6: UPDATE Inventory — Increment stock
        -- ---------------------------------------------------
        UPDATE Inventory
        SET
            AvailableQuantity = AvailableQuantity + @QuantityReceived,
            LastUpdated       = GETDATE()
        WHERE ProductID = @ProductID;

        -- ---------------------------------------------------
        -- Step 7: Call fn_GetAvailableStock again
        --         Get updated stock level after increment
        -- ---------------------------------------------------
        SET @UpdatedStockLevel = dbo.fn_GetAvailableStock(@ProductID);

        -- ---------------------------------------------------
        -- Step 8: COMMIT Transaction
        -- ---------------------------------------------------
        COMMIT TRANSACTION;

        -- ---------------------------------------------------
        -- Step 9: Set Success Message
        -- ---------------------------------------------------
        SET @StatusMessage = 'SUCCESS: Stock replenishment completed. '
                           + 'PurchaseOrderID = '  + CAST(@PurchaseOrderID   AS VARCHAR(10))
                           + ', Previous Stock = '  + CAST(@CurrentStock       AS VARCHAR(10))
                           + ', Added = '           + CAST(@QuantityReceived   AS VARCHAR(10))
                           + ', Updated Stock = '   + CAST(@UpdatedStockLevel  AS VARCHAR(10));

    END TRY

    BEGIN CATCH

        ROLLBACK TRANSACTION;

        SET @PurchaseOrderID   = 0;
        SET @UpdatedStockLevel = 0;
        SET @StatusMessage     = 'ERROR: ' + ERROR_MESSAGE()
                               + ' | Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));

    END CATCH;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
/*
DECLARE @PurchaseOrderID INT, @UpdatedStockLevel INT, @StatusMessage VARCHAR(255);

-- Test 1: Valid Replenishment — TechWorld supplies Laptop (Electronics)
EXEC usp_ProcessStockReplenishment 1, 1, 100,
     @PurchaseOrderID OUTPUT, @UpdatedStockLevel OUTPUT, @StatusMessage OUTPUT;
SELECT @PurchaseOrderID AS POID, @UpdatedStockLevel AS NewStock, @StatusMessage AS StatusMessage;
-- Expected: SUCCESS, stock increases by 100

-- Test 2: Quantity = 0
EXEC usp_ProcessStockReplenishment 1, 1, 0,
     @PurchaseOrderID OUTPUT, @UpdatedStockLevel OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: QuantityReceived must be greater than 0.

-- Test 3: Supplier not authorized for category
-- SupplierID 2 (Fashion Hub) trying to supply Electronics
EXEC usp_ProcessStockReplenishment 1, 2, 50,
     @PurchaseOrderID OUTPUT, @UpdatedStockLevel OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: SupplierID 2 is not authorized to supply category: 'Electronics'.

-- Test 4: Discontinued Product
EXEC usp_ProcessStockReplenishment 12, 1, 50,
     @PurchaseOrderID OUTPUT, @UpdatedStockLevel OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Product does not exist or is discontinued.

-- Test 5: Inactive Supplier
EXEC usp_ProcessStockReplenishment 10, 5, 50,
     @PurchaseOrderID OUTPUT, @UpdatedStockLevel OUTPUT, @StatusMessage OUTPUT;
SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: SupplierID 5 is not Active.
*/
