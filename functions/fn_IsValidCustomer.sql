-- ============================================================
--   FUNCTION  : fn_IsValidCustomer
--   DOMAIN    : Retail
--   PURPOSE   : Validates if a customer exists and is Active
--   INPUT     : @CustomerID INT
--   RETURNS   : BIT → 1 = Valid/Active, 0 = Invalid/Inactive
--   TABLES    : Customers
--   CALLED BY : usp_PlaceOrder
--               usp_ProcessReturn
--               usp_GetCustomerOrderSummary
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.fn_IsValidCustomer', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_IsValidCustomer;
GO

CREATE FUNCTION fn_IsValidCustomer
(
    @CustomerID   INT           -- INPUT: Customer ID to validate
)
RETURNS BIT                     -- OUTPUT: 1 = Active, 0 = Inactive/Not Found
AS
BEGIN

    -- Step 1: Declare variable to hold result
    DECLARE @Result   BIT;

    -- Step 2: Check if CustomerID exists with Status = 'Active'
    SELECT
        @Result = CASE
                      WHEN Status = 'Active'   THEN 1    -- Active customer
                      WHEN Status = 'Inactive' THEN 0    -- Inactive customer
                      ELSE 0                             -- Should not occur
                  END
    FROM Customers
    WHERE CustomerID = @CustomerID;

    -- Step 3: If CustomerID not found at all, @Result will be NULL
    IF @Result IS NULL
        SET @Result = 0;    -- Treat not found as invalid

    -- Step 4: Return result
    RETURN @Result;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
-- SELECT dbo.fn_IsValidCustomer(1)    → Expected: 1 (Silver/Active)
-- SELECT dbo.fn_IsValidCustomer(4)    → Expected: 0 (Gold/Inactive)
-- SELECT dbo.fn_IsValidCustomer(9999) → Expected: 0 (Not Found)
