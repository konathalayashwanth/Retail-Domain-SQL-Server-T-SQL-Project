-- ============================================================
--   FUNCTION  : fn_GetCustomerDiscountRate
--   DOMAIN    : Retail
--   PURPOSE   : Returns discount % based on customer tier
--   INPUT     : @CustomerID INT
--   RETURNS   : DECIMAL(5,2) → Discount percentage
--               Silver   =  5.00%
--               Gold     = 10.00%
--               Platinum = 15.00%
--               Inactive/Not Found = 0.00%
--   TABLES    : Customers
--   CALLED BY : fn_CalculateOrderTotal (internally)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.fn_GetCustomerDiscountRate', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetCustomerDiscountRate;
GO

CREATE FUNCTION fn_GetCustomerDiscountRate
(
    @CustomerID   INT             -- INPUT: Customer ID
)
RETURNS DECIMAL(5,2)             -- OUTPUT: Discount percentage
AS
BEGIN

    -- Step 1: Declare variables
    DECLARE @CustomerTier   VARCHAR(20);
    DECLARE @DiscountRate   DECIMAL(5,2);

    -- Step 2: Fetch CustomerTier from Customers table
    --         Only Active customers are eligible for discount
    SELECT
        @CustomerTier = CustomerTier
    FROM Customers
    WHERE CustomerID = @CustomerID
    AND   Status     = 'Active';

    -- Step 3: Map CustomerTier to Discount Rate
    SET @DiscountRate = CASE @CustomerTier
                            WHEN 'Silver'   THEN  5.00   -- 5%  discount
                            WHEN 'Gold'     THEN 10.00   -- 10% discount
                            WHEN 'Platinum' THEN 15.00   -- 15% discount
                            ELSE             0.00        -- No discount
                        END;

    -- Step 4: Return the discount rate
    RETURN @DiscountRate;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
-- SELECT dbo.fn_GetCustomerDiscountRate(1)    → Expected:  5.00 (Silver)
-- SELECT dbo.fn_GetCustomerDiscountRate(2)    → Expected: 10.00 (Gold)
-- SELECT dbo.fn_GetCustomerDiscountRate(3)    → Expected: 15.00 (Platinum)
-- SELECT dbo.fn_GetCustomerDiscountRate(4)    → Expected:  0.00 (Inactive)
-- SELECT dbo.fn_GetCustomerDiscountRate(9999) → Expected:  0.00 (Not Found)
