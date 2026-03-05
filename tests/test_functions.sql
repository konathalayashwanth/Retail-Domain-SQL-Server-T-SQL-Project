-- ============================================================
--   TEST FILE : test_functions.sql
--   DOMAIN    : Retail
--   PURPOSE   : Tests all 6 scalar functions
--   RUN AFTER : All tables and functions are created
-- ============================================================

USE RetailDB;
GO

PRINT '============================================================';
PRINT '  RETAIL DOMAIN — FUNCTION TEST SUITE';
PRINT '============================================================';

-- ============================================================
-- TEST 1: fn_IsValidCustomer
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST: fn_IsValidCustomer';
PRINT '------------------------------------------------------------';

SELECT
    'CustomerID=1 (Silver/Active)'    AS TestCase,
    dbo.fn_IsValidCustomer(1)         AS Result,
    '1'                               AS Expected;

SELECT
    'CustomerID=2 (Gold/Active)'      AS TestCase,
    dbo.fn_IsValidCustomer(2)         AS Result,
    '1'                               AS Expected;

SELECT
    'CustomerID=3 (Platinum/Active)'  AS TestCase,
    dbo.fn_IsValidCustomer(3)         AS Result,
    '1'                               AS Expected;

SELECT
    'CustomerID=4 (Gold/Inactive)'    AS TestCase,
    dbo.fn_IsValidCustomer(4)         AS Result,
    '0'                               AS Expected;

SELECT
    'CustomerID=9999 (Not Found)'     AS TestCase,
    dbo.fn_IsValidCustomer(9999)      AS Result,
    '0'                               AS Expected;

-- ============================================================
-- TEST 2: fn_GetAvailableStock
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST: fn_GetAvailableStock';
PRINT '------------------------------------------------------------';

SELECT
    'ProductID=1 (Laptop)'            AS TestCase,
    dbo.fn_GetAvailableStock(1)       AS Result,
    '50'                              AS Expected;

SELECT
    'ProductID=2 (Mobile)'            AS TestCase,
    dbo.fn_GetAvailableStock(2)       AS Result,
    '80'                              AS Expected;

SELECT
    'ProductID=3 (Headphones)'        AS TestCase,
    dbo.fn_GetAvailableStock(3)       AS Result,
    '120'                             AS Expected;

SELECT
    'ProductID=9999 (Not Found)'      AS TestCase,
    dbo.fn_GetAvailableStock(9999)    AS Result,
    '0'                               AS Expected;

-- ============================================================
-- TEST 3: fn_GetCustomerDiscountRate
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST: fn_GetCustomerDiscountRate';
PRINT '------------------------------------------------------------';

SELECT
    'CustomerID=1 (Silver  5%)'         AS TestCase,
    dbo.fn_GetCustomerDiscountRate(1)   AS Result,
    '5.00'                              AS Expected;

SELECT
    'CustomerID=2 (Gold   10%)'         AS TestCase,
    dbo.fn_GetCustomerDiscountRate(2)   AS Result,
    '10.00'                             AS Expected;

SELECT
    'CustomerID=3 (Platinum 15%)'       AS TestCase,
    dbo.fn_GetCustomerDiscountRate(3)   AS Result,
    '15.00'                             AS Expected;

SELECT
    'CustomerID=4 (Inactive  0%)'       AS TestCase,
    dbo.fn_GetCustomerDiscountRate(4)   AS Result,
    '0.00'                              AS Expected;

SELECT
    'CustomerID=9999 (Not Found 0%)'    AS TestCase,
    dbo.fn_GetCustomerDiscountRate(9999) AS Result,
    '0.00'                              AS Expected;

-- ============================================================
-- TEST 4: fn_CalculateOrderTotal
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST: fn_CalculateOrderTotal';
PRINT '  (Based on sample orders in OrderItems)';
PRINT '------------------------------------------------------------';

SELECT
    'OrderID=1 (Silver 5%, SubTotal=70000)'     AS TestCase,
    dbo.fn_CalculateOrderTotal(1)               AS Result,
    '66500.00'                                  AS Expected;
-- SubTotal=70,000 | Discount=3,500 (5%) | Final=66,500

SELECT
    'OrderID=2 (Gold 10%, SubTotal=60000)'      AS TestCase,
    dbo.fn_CalculateOrderTotal(2)               AS Result,
    '54000.00'                                  AS Expected;
-- SubTotal=60,000 | Discount=6,000 (10%) | Final=54,000

SELECT
    'OrderID=3 (Platinum 15%, SubTotal=45000)'  AS TestCase,
    dbo.fn_CalculateOrderTotal(3)               AS Result,
    '38250.00'                                  AS Expected;
-- SubTotal=45,000 | Discount=6,750 (15%) | Final=38,250

SELECT
    'OrderID=9999 (Not Found)'                  AS TestCase,
    dbo.fn_CalculateOrderTotal(9999)            AS Result,
    '0.00'                                      AS Expected;

-- ============================================================
-- TEST 5: fn_CalculateTax
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST: fn_CalculateTax';
PRINT '------------------------------------------------------------';

SELECT
    'TX (8.25%), Amount=66500'          AS TestCase,
    dbo.fn_CalculateTax(66500.00,'TX') AS Result,
    '5486.25'                           AS Expected;
-- 66500 × 8.25% = 5,486.25

SELECT
    'CA (10.25%), Amount=54000'         AS TestCase,
    dbo.fn_CalculateTax(54000.00,'CA') AS Result,
    '5535.00'                           AS Expected;
-- 54000 × 10.25% = 5,535.00

SELECT
    'NY (8.52%), Amount=38250'          AS TestCase,
    dbo.fn_CalculateTax(38250.00,'NY') AS Result,
    '3258.90'                           AS Expected;
-- 38250 × 8.52% = 3,258.90

SELECT
    'FL (6.00%), Amount=45000'          AS TestCase,
    dbo.fn_CalculateTax(45000.00,'FL') AS Result,
    '2700.00'                           AS Expected;
-- 45000 × 6.00% = 2,700.00

SELECT
    'ZZ (Invalid State)'               AS TestCase,
    dbo.fn_CalculateTax(50000.00,'ZZ') AS Result,
    '0.00'                              AS Expected;

SELECT
    'NULL Amount'                       AS TestCase,
    dbo.fn_CalculateTax(NULL,'TX')     AS Result,
    '0.00'                              AS Expected;

SELECT
    'NULL StateCode'                    AS TestCase,
    dbo.fn_CalculateTax(50000.00,NULL) AS Result,
    '0.00'                              AS Expected;

SELECT
    'Zero Amount'                       AS TestCase,
    dbo.fn_CalculateTax(0.00,'TX')     AS Result,
    '0.00'                              AS Expected;

-- ============================================================
-- TEST 6: fn_GetProductCategory
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST: fn_GetProductCategory';
PRINT '------------------------------------------------------------';

SELECT
    'ProductID=1 (Laptop)'              AS TestCase,
    dbo.fn_GetProductCategory(1)        AS Result,
    'Electronics'                       AS Expected;

SELECT
    'ProductID=4 (T-Shirt)'             AS TestCase,
    dbo.fn_GetProductCategory(4)        AS Result,
    'Clothing'                          AS Expected;

SELECT
    'ProductID=6 (Rice 5KG)'            AS TestCase,
    dbo.fn_GetProductCategory(6)        AS Result,
    'Groceries'                         AS Expected;

SELECT
    'ProductID=8 (Office Chair)'        AS TestCase,
    dbo.fn_GetProductCategory(8)        AS Result,
    'Furniture'                         AS Expected;

SELECT
    'ProductID=10 (Cricket Bat)'        AS TestCase,
    dbo.fn_GetProductCategory(10)       AS Result,
    'Sports'                            AS Expected;

SELECT
    'ProductID=12 (Discontinued)'       AS TestCase,
    ISNULL(dbo.fn_GetProductCategory(12), 'NULL') AS Result,
    'NULL'                              AS Expected;

SELECT
    'ProductID=9999 (Not Found)'        AS TestCase,
    ISNULL(dbo.fn_GetProductCategory(9999), 'NULL') AS Result,
    'NULL'                              AS Expected;

SELECT
    'ProductID=NULL (NULL Input)'       AS TestCase,
    ISNULL(dbo.fn_GetProductCategory(NULL), 'NULL') AS Result,
    'NULL'                              AS Expected;

PRINT '';
PRINT '============================================================';
PRINT '  ALL FUNCTION TESTS COMPLETE';
PRINT '============================================================';
GO
