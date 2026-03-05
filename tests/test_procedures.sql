-- ============================================================
--   TEST FILE : test_procedures.sql
--   DOMAIN    : Retail
--   PURPOSE   : Tests all 5 stored procedures
--   RUN AFTER : test_functions.sql passes successfully
-- ============================================================

USE RetailDB;
GO

PRINT '============================================================';
PRINT '  RETAIL DOMAIN — STORED PROCEDURE TEST SUITE';
PRINT '============================================================';

-- Shared output variable declarations
DECLARE @OrderID             INT;
DECLARE @TotalAmount         DECIMAL(10,2);
DECLARE @InvoiceID           INT;
DECLARE @InvoiceTotalWithTax DECIMAL(10,2);
DECLARE @RefundAmount        DECIMAL(10,2);
DECLARE @ReturnID            INT;
DECLARE @PurchaseOrderID     INT;
DECLARE @UpdatedStockLevel   INT;
DECLARE @TotalOrders         INT;
DECLARE @TotalSpent          DECIMAL(10,2);
DECLARE @StatusMessage       VARCHAR(255);

-- ============================================================
-- TEST SUITE 1: usp_PlaceOrder
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST SUITE: usp_PlaceOrder';
PRINT '------------------------------------------------------------';

-- --------------------------------------------------
-- Test 1.1: VALID Order — CustomerID=1 (Silver 5%)
--           ProductID=1 (Laptop 50,000) × Qty=2
--           SubTotal=100,000 | Discount=5,000
--           Expected TotalAmount = 95,000.00
-- --------------------------------------------------
PRINT 'Test 1.1: Valid Order (Silver Customer, Laptop x2)';
EXEC usp_PlaceOrder
    @CustomerID    = 1,
    @ProductID     = 1,
    @Quantity      = 2,
    @OrderID       = @OrderID       OUTPUT,
    @TotalAmount   = @TotalAmount   OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT
    @OrderID       AS OrderID,
    @TotalAmount   AS TotalAmount,
    @StatusMessage AS StatusMessage;
-- Expected: SUCCESS | OrderID generated | TotalAmount = 95000.00

-- --------------------------------------------------
-- Test 1.2: VALID Order — CustomerID=2 (Gold 10%)
--           ProductID=3 (Headphones 5,000) × Qty=3
--           SubTotal=15,000 | Discount=1,500
--           Expected TotalAmount = 13,500.00
-- --------------------------------------------------
PRINT 'Test 1.2: Valid Order (Gold Customer, Headphones x3)';
EXEC usp_PlaceOrder
    @CustomerID    = 2,
    @ProductID     = 3,
    @Quantity      = 3,
    @OrderID       = @OrderID       OUTPUT,
    @TotalAmount   = @TotalAmount   OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT
    @OrderID       AS OrderID,
    @TotalAmount   AS TotalAmount,
    @StatusMessage AS StatusMessage;
-- Expected: SUCCESS | TotalAmount = 13500.00

-- --------------------------------------------------
-- Test 1.3: ERROR — Invalid CustomerID
-- --------------------------------------------------
PRINT 'Test 1.3: ERROR — Invalid CustomerID';
EXEC usp_PlaceOrder
    @CustomerID    = 9999,
    @ProductID     = 1,
    @Quantity      = 1,
    @OrderID       = @OrderID       OUTPUT,
    @TotalAmount   = @TotalAmount   OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer.

-- --------------------------------------------------
-- Test 1.4: ERROR — Inactive Customer (CustomerID=4)
-- --------------------------------------------------
PRINT 'Test 1.4: ERROR — Inactive Customer';
EXEC usp_PlaceOrder
    @CustomerID    = 4,
    @ProductID     = 1,
    @Quantity      = 1,
    @OrderID       = @OrderID       OUTPUT,
    @TotalAmount   = @TotalAmount   OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer.

-- --------------------------------------------------
-- Test 1.5: ERROR — Insufficient Stock
-- --------------------------------------------------
PRINT 'Test 1.5: ERROR — Insufficient Stock';
EXEC usp_PlaceOrder
    @CustomerID    = 1,
    @ProductID     = 1,
    @Quantity      = 99999,
    @OrderID       = @OrderID       OUTPUT,
    @TotalAmount   = @TotalAmount   OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Insufficient stock.

-- --------------------------------------------------
-- Test 1.6: ERROR — Invalid Quantity (zero)
-- --------------------------------------------------
PRINT 'Test 1.6: ERROR — Quantity = 0';
EXEC usp_PlaceOrder
    @CustomerID    = 1,
    @ProductID     = 1,
    @Quantity      = 0,
    @OrderID       = @OrderID       OUTPUT,
    @TotalAmount   = @TotalAmount   OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Quantity must be greater than 0.

-- --------------------------------------------------
-- Test 1.7: ERROR — Discontinued Product
-- --------------------------------------------------
PRINT 'Test 1.7: ERROR — Discontinued Product';
EXEC usp_PlaceOrder
    @CustomerID    = 1,
    @ProductID     = 12,
    @Quantity      = 1,
    @OrderID       = @OrderID       OUTPUT,
    @TotalAmount   = @TotalAmount   OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Product does not exist or is discontinued.

-- ============================================================
-- TEST SUITE 2: usp_GenerateInvoice
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST SUITE: usp_GenerateInvoice';
PRINT '------------------------------------------------------------';

-- --------------------------------------------------
-- Test 2.1: VALID Invoice — OrderID=1, StateCode=TX
--           SubTotal=66,500 | Tax=5,486.25 (8.25%)
--           Expected TotalWithTax = 71,986.25
-- (OrderID 1 = from original sample data, Confirmed)
-- --------------------------------------------------
PRINT 'Test 2.1: Valid Invoice — Order 1, State TX';
EXEC usp_GenerateInvoice
    @OrderID             = 1,
    @StateCode           = 'TX',
    @InvoiceID           = @InvoiceID           OUTPUT,
    @InvoiceTotalWithTax = @InvoiceTotalWithTax OUTPUT,
    @StatusMessage       = @StatusMessage       OUTPUT;

SELECT
    @InvoiceID           AS InvoiceID,
    @InvoiceTotalWithTax AS TotalWithTax,
    @StatusMessage       AS StatusMessage;
-- Expected: SUCCESS | TotalWithTax = 71986.25

-- --------------------------------------------------
-- Test 2.2: ERROR — Order Already Invoiced
-- --------------------------------------------------
PRINT 'Test 2.2: ERROR — Already Invoiced';
EXEC usp_GenerateInvoice
    @OrderID             = 1,
    @StateCode           = 'TX',
    @InvoiceID           = @InvoiceID           OUTPUT,
    @InvoiceTotalWithTax = @InvoiceTotalWithTax OUTPUT,
    @StatusMessage       = @StatusMessage       OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: OrderID 1 is already Invoiced.

-- --------------------------------------------------
-- Test 2.3: ERROR — NULL StateCode
-- --------------------------------------------------
PRINT 'Test 2.3: ERROR — NULL StateCode';
EXEC usp_GenerateInvoice
    @OrderID             = 2,
    @StateCode           = NULL,
    @InvoiceID           = @InvoiceID           OUTPUT,
    @InvoiceTotalWithTax = @InvoiceTotalWithTax OUTPUT,
    @StatusMessage       = @StatusMessage       OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: StateCode must not be NULL or empty.

-- --------------------------------------------------
-- Test 2.4: ERROR — Non-Existing OrderID
-- --------------------------------------------------
PRINT 'Test 2.4: ERROR — Non-Existing OrderID';
EXEC usp_GenerateInvoice
    @OrderID             = 9999,
    @StateCode           = 'TX',
    @InvoiceID           = @InvoiceID           OUTPUT,
    @InvoiceTotalWithTax = @InvoiceTotalWithTax OUTPUT,
    @StatusMessage       = @StatusMessage       OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: OrderID 9999 does not exist.

-- ============================================================
-- TEST SUITE 3: usp_ProcessReturn
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST SUITE: usp_ProcessReturn';
PRINT '------------------------------------------------------------';

-- --------------------------------------------------
-- Test 3.1: VALID Return
--           Order 1 must be Invoiced before returning
-- --------------------------------------------------
PRINT 'Test 3.1: Valid Return — Order 1, Customer 1';
EXEC usp_ProcessReturn
    @OrderID       = 1,
    @CustomerID    = 1,
    @ReturnReason  = 'Product damaged on arrival',
    @RefundAmount  = @RefundAmount  OUTPUT,
    @ReturnID      = @ReturnID      OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT
    @ReturnID      AS ReturnID,
    @RefundAmount  AS RefundAmount,
    @StatusMessage AS StatusMessage;
-- Expected: SUCCESS | ReturnID generated | RefundAmount = 66500.00

-- --------------------------------------------------
-- Test 3.2: ERROR — Order Already Returned
-- --------------------------------------------------
PRINT 'Test 3.2: ERROR — Already Returned';
EXEC usp_ProcessReturn
    @OrderID       = 1,
    @CustomerID    = 1,
    @ReturnReason  = 'Trying again',
    @RefundAmount  = @RefundAmount  OUTPUT,
    @ReturnID      = @ReturnID      OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: OrderID 1 has already been Returned.

-- --------------------------------------------------
-- Test 3.3: ERROR — Invalid Customer
-- --------------------------------------------------
PRINT 'Test 3.3: ERROR — Invalid Customer';
EXEC usp_ProcessReturn
    @OrderID       = 2,
    @CustomerID    = 9999,
    @ReturnReason  = 'Defective product',
    @RefundAmount  = @RefundAmount  OUTPUT,
    @ReturnID      = @ReturnID      OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer.

-- --------------------------------------------------
-- Test 3.4: ERROR — NULL ReturnReason
-- --------------------------------------------------
PRINT 'Test 3.4: ERROR — NULL ReturnReason';
EXEC usp_ProcessReturn
    @OrderID       = 2,
    @CustomerID    = 2,
    @ReturnReason  = NULL,
    @RefundAmount  = @RefundAmount  OUTPUT,
    @ReturnID      = @ReturnID      OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Return reason must not be NULL or empty.

-- --------------------------------------------------
-- Test 3.5: ERROR — Order does not belong to customer
-- --------------------------------------------------
PRINT 'Test 3.5: ERROR — Order belongs to different customer';
EXEC usp_ProcessReturn
    @OrderID       = 3,
    @CustomerID    = 1,
    @ReturnReason  = 'Wrong customer test',
    @RefundAmount  = @RefundAmount  OUTPUT,
    @ReturnID      = @ReturnID      OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: OrderID 3 does not belong to CustomerID 1.

-- ============================================================
-- TEST SUITE 4: usp_ProcessStockReplenishment
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST SUITE: usp_ProcessStockReplenishment';
PRINT '------------------------------------------------------------';

-- --------------------------------------------------
-- Test 4.1: VALID Replenishment
--           ProductID=1 (Laptop/Electronics)
--           SupplierID=1 (TechWorld → authorized for Electronics)
--           Qty=100 added to current stock
-- --------------------------------------------------
PRINT 'Test 4.1: Valid Replenishment — Laptop, TechWorld, Qty=100';
EXEC usp_ProcessStockReplenishment
    @ProductID         = 1,
    @SupplierID        = 1,
    @QuantityReceived  = 100,
    @PurchaseOrderID   = @PurchaseOrderID   OUTPUT,
    @UpdatedStockLevel = @UpdatedStockLevel OUTPUT,
    @StatusMessage     = @StatusMessage     OUTPUT;

SELECT
    @PurchaseOrderID   AS PurchaseOrderID,
    @UpdatedStockLevel AS UpdatedStockLevel,
    @StatusMessage     AS StatusMessage;
-- Expected: SUCCESS | PurchaseOrderID generated | UpdatedStockLevel = previous + 100

-- --------------------------------------------------
-- Test 4.2: ERROR — Quantity = 0
-- --------------------------------------------------
PRINT 'Test 4.2: ERROR — QuantityReceived = 0';
EXEC usp_ProcessStockReplenishment
    @ProductID         = 1,
    @SupplierID        = 1,
    @QuantityReceived  = 0,
    @PurchaseOrderID   = @PurchaseOrderID   OUTPUT,
    @UpdatedStockLevel = @UpdatedStockLevel OUTPUT,
    @StatusMessage     = @StatusMessage     OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: QuantityReceived must be greater than 0.

-- --------------------------------------------------
-- Test 4.3: ERROR — Supplier not authorized for category
--           SupplierID=2 (Fashion Hub) for Laptop (Electronics)
-- --------------------------------------------------
PRINT 'Test 4.3: ERROR — Supplier not authorized for category';
EXEC usp_ProcessStockReplenishment
    @ProductID         = 1,
    @SupplierID        = 2,
    @QuantityReceived  = 50,
    @PurchaseOrderID   = @PurchaseOrderID   OUTPUT,
    @UpdatedStockLevel = @UpdatedStockLevel OUTPUT,
    @StatusMessage     = @StatusMessage     OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: SupplierID 2 not authorized for category: 'Electronics'.

-- --------------------------------------------------
-- Test 4.4: ERROR — Discontinued Product
-- --------------------------------------------------
PRINT 'Test 4.4: ERROR — Discontinued Product';
EXEC usp_ProcessStockReplenishment
    @ProductID         = 12,
    @SupplierID        = 1,
    @QuantityReceived  = 50,
    @PurchaseOrderID   = @PurchaseOrderID   OUTPUT,
    @UpdatedStockLevel = @UpdatedStockLevel OUTPUT,
    @StatusMessage     = @StatusMessage     OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Product does not exist or is discontinued.

-- --------------------------------------------------
-- Test 4.5: ERROR — Inactive Supplier (SupplierID=5)
-- --------------------------------------------------
PRINT 'Test 4.5: ERROR — Inactive Supplier';
EXEC usp_ProcessStockReplenishment
    @ProductID         = 10,
    @SupplierID        = 5,
    @QuantityReceived  = 50,
    @PurchaseOrderID   = @PurchaseOrderID   OUTPUT,
    @UpdatedStockLevel = @UpdatedStockLevel OUTPUT,
    @StatusMessage     = @StatusMessage     OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: SupplierID 5 is not Active.

-- ============================================================
-- TEST SUITE 5: usp_GetCustomerOrderSummary
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT '  TEST SUITE: usp_GetCustomerOrderSummary';
PRINT '------------------------------------------------------------';

-- --------------------------------------------------
-- Test 5.1: VALID Summary — CustomerID=1 (Rajesh)
-- --------------------------------------------------
PRINT 'Test 5.1: Valid Summary — CustomerID=1, Full Year';
EXEC usp_GetCustomerOrderSummary
    @CustomerID    = 1,
    @FromDate      = '2024-01-01',
    @ToDate        = '2024-12-31',
    @TotalOrders   = @TotalOrders   OUTPUT,
    @TotalSpent    = @TotalSpent    OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT
    @TotalOrders   AS TotalOrders,
    @TotalSpent    AS TotalSpent,
    @StatusMessage AS StatusMessage;
-- Expected: SUCCESS with TotalOrders and TotalSpent

-- --------------------------------------------------
-- Test 5.2: VALID Summary — CustomerID=2 (Priya)
-- --------------------------------------------------
PRINT 'Test 5.2: Valid Summary — CustomerID=2';
EXEC usp_GetCustomerOrderSummary
    @CustomerID    = 2,
    @FromDate      = '2024-01-01',
    @ToDate        = '2024-12-31',
    @TotalOrders   = @TotalOrders   OUTPUT,
    @TotalSpent    = @TotalSpent    OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT
    @TotalOrders   AS TotalOrders,
    @TotalSpent    AS TotalSpent,
    @StatusMessage AS StatusMessage;
-- Expected: SUCCESS

-- --------------------------------------------------
-- Test 5.3: ERROR — FromDate > ToDate
-- --------------------------------------------------
PRINT 'Test 5.3: ERROR — FromDate > ToDate';
EXEC usp_GetCustomerOrderSummary
    @CustomerID    = 1,
    @FromDate      = '2024-12-31',
    @ToDate        = '2024-01-01',
    @TotalOrders   = @TotalOrders   OUTPUT,
    @TotalSpent    = @TotalSpent    OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: FromDate must be <= ToDate.

-- --------------------------------------------------
-- Test 5.4: ERROR — Date range > 365 days
-- --------------------------------------------------
PRINT 'Test 5.4: ERROR — Date range exceeds 365 days';
EXEC usp_GetCustomerOrderSummary
    @CustomerID    = 1,
    @FromDate      = '2023-01-01',
    @ToDate        = '2024-12-31',
    @TotalOrders   = @TotalOrders   OUTPUT,
    @TotalSpent    = @TotalSpent    OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Date range exceeds 365 days.

-- --------------------------------------------------
-- Test 5.5: ERROR — Invalid CustomerID
-- --------------------------------------------------
PRINT 'Test 5.5: ERROR — Invalid CustomerID';
EXEC usp_GetCustomerOrderSummary
    @CustomerID    = 9999,
    @FromDate      = '2024-01-01',
    @ToDate        = '2024-12-31',
    @TotalOrders   = @TotalOrders   OUTPUT,
    @TotalSpent    = @TotalSpent    OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer.

-- --------------------------------------------------
-- Test 5.6: ERROR — Inactive Customer (CustomerID=4)
-- --------------------------------------------------
PRINT 'Test 5.6: ERROR — Inactive Customer';
EXEC usp_GetCustomerOrderSummary
    @CustomerID    = 4,
    @FromDate      = '2024-01-01',
    @ToDate        = '2024-12-31',
    @TotalOrders   = @TotalOrders   OUTPUT,
    @TotalSpent    = @TotalSpent    OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: Invalid or inactive customer. (Sneha is Inactive)

-- --------------------------------------------------
-- Test 5.7: ERROR — NULL Dates
-- --------------------------------------------------
PRINT 'Test 5.7: ERROR — NULL Dates';
EXEC usp_GetCustomerOrderSummary
    @CustomerID    = 1,
    @FromDate      = NULL,
    @ToDate        = NULL,
    @TotalOrders   = @TotalOrders   OUTPUT,
    @TotalSpent    = @TotalSpent    OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @StatusMessage AS StatusMessage;
-- Expected: ERROR: FromDate and ToDate must not be NULL.

PRINT '';
PRINT '============================================================';
PRINT '  ALL STORED PROCEDURE TESTS COMPLETE';
PRINT '============================================================';
GO
