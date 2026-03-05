-- ============================================================
--   FUNCTION  : fn_GetAvailableStock
--   DOMAIN    : Retail
--   PURPOSE   : Returns current available stock for a product
--   INPUT     : @ProductID INT
--   RETURNS   : INT → Available stock quantity (0 if not found)
--   TABLES    : Inventory
--   CALLED BY : usp_PlaceOrder
--               usp_ProcessStockReplenishment
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.fn_GetAvailableStock', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetAvailableStock;
GO

CREATE FUNCTION fn_GetAvailableStock
(
    @ProductID    INT           -- INPUT: Product ID to check stock
)
RETURNS INT                     -- OUTPUT: Available quantity in stock
AS
BEGIN

    -- Step 1: Declare variable to hold available quantity
    DECLARE @InventoryQty   INT;

    -- Step 2: Fetch AvailableQuantity from Inventory table
    SELECT
        @InventoryQty = AvailableQuantity
    FROM Inventory
    WHERE ProductID = @ProductID;

    -- Step 3: Return 0 if ProductID not found in Inventory
    RETURN ISNULL(@InventoryQty, 0);

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
-- SELECT dbo.fn_GetAvailableStock(1)    → Expected: 50  (Laptop)
-- SELECT dbo.fn_GetAvailableStock(2)    → Expected: 80  (Mobile)
-- SELECT dbo.fn_GetAvailableStock(9999) → Expected: 0   (Not Found)
