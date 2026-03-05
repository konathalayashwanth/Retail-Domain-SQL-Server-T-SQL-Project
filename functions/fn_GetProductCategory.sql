-- ============================================================
--   FUNCTION  : fn_GetProductCategory
--   DOMAIN    : Retail
--   PURPOSE   : Returns category name for a given product
--   INPUT     : @ProductID INT
--   RETURNS   : VARCHAR(50) → Category name (NULL if not found)
--   TABLES    : Products, Categories (INNER JOIN)
--   CALLED BY : usp_ProcessStockReplenishment
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.fn_GetProductCategory', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetProductCategory;
GO

CREATE FUNCTION fn_GetProductCategory
(
    @ProductID    INT             -- INPUT: Product ID
)
RETURNS VARCHAR(50)               -- OUTPUT: Category name or NULL
AS
BEGIN

    -- Step 1: Declare variable to hold category name
    DECLARE @CategoryName   VARCHAR(50);

    -- Step 2: Validate input — return NULL for NULL ProductID
    IF @ProductID IS NULL
        RETURN NULL;

    -- Step 3: JOIN Products and Categories to fetch CategoryName
    --         Only Active products are considered
    SELECT
        @CategoryName = C.CategoryName
    FROM Products    P
    INNER JOIN Categories C
        ON  P.CategoryID = C.CategoryID    -- JOIN condition
    WHERE P.ProductID    = @ProductID      -- Filter by ProductID
    AND   P.Status       = 'Active';       -- Only Active products

    -- Step 4: Return CategoryName (NULL if not found or Discontinued)
    RETURN @CategoryName;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
-- SELECT dbo.fn_GetProductCategory(1)    → Expected: 'Electronics'  (Laptop)
-- SELECT dbo.fn_GetProductCategory(4)    → Expected: 'Clothing'     (T-Shirt)
-- SELECT dbo.fn_GetProductCategory(6)    → Expected: 'Groceries'    (Rice)
-- SELECT dbo.fn_GetProductCategory(8)    → Expected: 'Furniture'    (Office Chair)
-- SELECT dbo.fn_GetProductCategory(10)   → Expected: 'Sports'       (Cricket Bat)
-- SELECT dbo.fn_GetProductCategory(12)   → Expected: NULL           (Discontinued)
-- SELECT dbo.fn_GetProductCategory(9999) → Expected: NULL           (Not Found)
-- SELECT dbo.fn_GetProductCategory(NULL) → Expected: NULL           (NULL Input)
