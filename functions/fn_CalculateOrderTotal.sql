-- ============================================================
--   FUNCTION  : fn_CalculateOrderTotal
--   DOMAIN    : Retail
--   PURPOSE   : Calculates final order total after discount
--   INPUT     : @OrderID INT
--   RETURNS   : DECIMAL(10,2) → Final total after discount
--   TABLES    : Orders, OrderItems
--   CALLS     : fn_GetCustomerDiscountRate (internally)
--   CALLED BY : usp_PlaceOrder
--               usp_GenerateInvoice
--               usp_ProcessReturn
--               usp_GetCustomerOrderSummary
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.fn_CalculateOrderTotal', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalculateOrderTotal;
GO

CREATE FUNCTION fn_CalculateOrderTotal
(
    @OrderID      INT              -- INPUT: Order ID
)
RETURNS DECIMAL(10,2)             -- OUTPUT: Final total after discount
AS
BEGIN

    -- Step 1: Declare variables
    DECLARE @CustomerID       INT;
    DECLARE @SubTotal         DECIMAL(10,2);
    DECLARE @DiscountRate     DECIMAL(5,2);
    DECLARE @DiscountAmount   DECIMAL(10,2);
    DECLARE @FinalTotal       DECIMAL(10,2);

    -- Step 2: Get CustomerID from Orders table
    SELECT
        @CustomerID = CustomerID
    FROM Orders
    WHERE OrderID = @OrderID;

    -- Step 3: Calculate SubTotal from OrderItems
    --         SUM of (Quantity × UnitPrice) for all items in this order
    SELECT
        @SubTotal = SUM(Quantity * UnitPrice)
    FROM OrderItems
    WHERE OrderID = @OrderID;

    -- Step 4: Handle NULL SubTotal (OrderID has no items)
    IF @SubTotal IS NULL
        SET @SubTotal = 0.00;

    -- Step 5: Call fn_GetCustomerDiscountRate
    --         Get discount % based on customer tier
    SET @DiscountRate = dbo.fn_GetCustomerDiscountRate(@CustomerID);

    -- Step 6: Calculate Discount Amount
    --         DiscountAmount = SubTotal × (DiscountRate / 100)
    SET @DiscountAmount = @SubTotal * (@DiscountRate / 100);

    -- Step 7: Calculate Final Total after Discount
    --         FinalTotal = SubTotal - DiscountAmount
    SET @FinalTotal = @SubTotal - @DiscountAmount;

    -- Step 8: Return Final Total
    RETURN @FinalTotal;

END;
GO

-- ============================================================
-- Test Cases (based on sample data)
-- ============================================================
-- Order 1: SubTotal=70,000  Silver 5%   → Expected: 66,500.00
-- Order 2: SubTotal=60,000  Gold   10%  → Expected: 54,000.00
-- Order 3: SubTotal=45,000  Platinum15% → Expected: 38,250.00
--
-- SELECT dbo.fn_CalculateOrderTotal(1)    → Expected: 66500.00
-- SELECT dbo.fn_CalculateOrderTotal(2)    → Expected: 54000.00
-- SELECT dbo.fn_CalculateOrderTotal(3)    → Expected: 38250.00
-- SELECT dbo.fn_CalculateOrderTotal(9999) → Expected:     0.00
