
# 🏪 Retail Domain — SQL Server T-SQL Project

![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-blue?style=for-the-badge&logo=microsoftsqlserver)
![Domain](https://img.shields.io/badge/Domain-Retail-orange?style=for-the-badge)
![Objects](https://img.shields.io/badge/DB%20Objects-23-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)

A fully structured **Retail Domain Database** built with **Microsoft SQL Server (T-SQL)**, featuring production-grade Stored Procedures, Scalar Functions, and normalized tables. This project demonstrates real-world database programming patterns including transaction management, error handling, input validation, and modular function reuse.

---

## 📁 Project Structure

```
retail-tsql-project/
│
├── 📂 tables/
│   ├── 01_Categories.sql
│   ├── 02_Customers.sql
│   ├── 03_Suppliers.sql
│   ├── 04_TaxRates.sql
│   ├── 05_Products.sql
│   ├── 06_SupplierCategories.sql
│   ├── 07_Orders.sql
│   ├── 08_OrderItems.sql
│   ├── 09_Inventory.sql
│   ├── 10_Invoices.sql
│   ├── 11_Returns.sql
│   └── 12_PurchaseOrders.sql
│
├── 📂 functions/
│   ├── fn_IsValidCustomer.sql
│   ├── fn_GetAvailableStock.sql
│   ├── fn_GetCustomerDiscountRate.sql
│   ├── fn_CalculateOrderTotal.sql
│   ├── fn_CalculateTax.sql
│   └── fn_GetProductCategory.sql
│
├── 📂 stored_procedures/
│   ├── usp_PlaceOrder.sql
│   ├── usp_GenerateInvoice.sql
│   ├── usp_ProcessReturn.sql
│   ├── usp_ProcessStockReplenishment.sql
│   └── usp_GetCustomerOrderSummary.sql
│
├── 📂 tests/
│   ├── test_functions.sql
│   └── test_procedures.sql
│
└── README.md
```

---

## 🗄️ Database Schema — 12 Tables

| # | Table | Description | Key Relationships |
|---|---|---|---|
| 1 | `Categories` | Product categories | Parent of Products |
| 2 | `Customers` | Customer master data with tier | Parent of Orders, Returns |
| 3 | `Suppliers` | Supplier master data | Parent of PurchaseOrders |
| 4 | `TaxRates` | State-wise tax rates | Used by fn_CalculateTax |
| 5 | `Products` | Product catalog with pricing | FK → Categories |
| 6 | `SupplierCategories` | Supplier-Category authorization | FK → Suppliers, Categories |
| 7 | `Orders` | Order header records | FK → Customers |
| 8 | `OrderItems` | Order line items | FK → Orders, Products |
| 9 | `Inventory` | Real-time stock levels | FK → Products |
| 10 | `Invoices` | Invoice records | FK → Orders |
| 11 | `Returns` | Return and refund records | FK → Orders, Customers |
| 12 | `PurchaseOrders` | Stock replenishment records | FK → Products, Suppliers |

---

## ⚙️ Scalar Functions — 6 Functions

All functions are **deterministic scalar functions** called inside stored procedures.

### `fn_IsValidCustomer(@CustomerID)`
- **Returns:** `BIT` (1 = Active, 0 = Inactive/Not Found)
- **Logic:** Validates customer existence and active status
- **Called By:** `usp_PlaceOrder`, `usp_ProcessReturn`, `usp_GetCustomerOrderSummary`

### `fn_GetAvailableStock(@ProductID)`
- **Returns:** `INT` — current stock quantity
- **Logic:** Reads `AvailableQuantity` from Inventory table
- **Called By:** `usp_PlaceOrder`, `usp_ProcessStockReplenishment`

### `fn_GetCustomerDiscountRate(@CustomerID)`
- **Returns:** `DECIMAL(5,2)` — discount percentage
- **Logic:** Silver = 5%, Gold = 10%, Platinum = 15%, Inactive/NotFound = 0%
- **Called By:** `usp_PlaceOrder` → via `fn_CalculateOrderTotal`

### `fn_CalculateOrderTotal(@OrderID)`
- **Returns:** `DECIMAL(10,2)` — final order total after discount
- **Logic:** SUM(Quantity × UnitPrice) → applies discount from `fn_GetCustomerDiscountRate`
- **Internally Calls:** `fn_GetCustomerDiscountRate`
- **Called By:** `usp_PlaceOrder`, `usp_GenerateInvoice`, `usp_ProcessReturn`, `usp_GetCustomerOrderSummary`

### `fn_CalculateTax(@Amount, @StateCode)`
- **Returns:** `DECIMAL(10,2)` — calculated tax amount
- **Logic:** Looks up latest TaxRate by StateCode, multiplies by amount
- **Called By:** `usp_GenerateInvoice`

### `fn_GetProductCategory(@ProductID)`
- **Returns:** `VARCHAR(50)` — category name
- **Logic:** INNER JOIN between Products and Categories tables
- **Called By:** `usp_ProcessStockReplenishment`

---

## 🗂️ Stored Procedures — 5 Procedures

### `usp_PlaceOrder`
Places a new customer order with full validation and inventory update.

| Parameter | Direction | Type |
|---|---|---|
| @CustomerID | IN | INT |
| @ProductID | IN | INT |
| @Quantity | IN | INT |
| @OrderID | OUT | INT |
| @TotalAmount | OUT | DECIMAL(10,2) |
| @StatusMessage | OUT | VARCHAR(255) |

**Validations:** Quantity > 0 · Product exists · Valid customer · Sufficient stock  
**Functions Called:** `fn_IsValidCustomer` → `fn_GetAvailableStock` → `fn_GetCustomerDiscountRate` → `fn_CalculateOrderTotal`

---

### `usp_GenerateInvoice`
Generates an invoice for a confirmed order including tax calculation.

| Parameter | Direction | Type |
|---|---|---|
| @OrderID | IN | INT |
| @StateCode | IN | VARCHAR(5) |
| @InvoiceID | OUT | INT |
| @InvoiceTotalWithTax | OUT | DECIMAL(10,2) |
| @StatusMessage | OUT | VARCHAR(255) |

**Validations:** Order exists · Status = 'Confirmed' · StateCode not NULL  
**Functions Called:** `fn_CalculateOrderTotal` → `fn_CalculateTax`

---

### `usp_ProcessReturn`
Processes a return request, restores inventory, and calculates refund.

| Parameter | Direction | Type |
|---|---|---|
| @OrderID | IN | INT |
| @CustomerID | IN | INT |
| @ReturnReason | IN | VARCHAR(255) |
| @RefundAmount | OUT | DECIMAL(10,2) |
| @ReturnID | OUT | INT |
| @StatusMessage | OUT | VARCHAR(255) |

**Validations:** Valid customer · Order belongs to customer · Status = Invoiced/Delivered · Within 30 days · ReturnReason not NULL  
**Functions Called:** `fn_IsValidCustomer` → `fn_CalculateOrderTotal`

---

### `usp_ProcessStockReplenishment`
Restocks inventory from an authorized supplier.

| Parameter | Direction | Type |
|---|---|---|
| @ProductID | IN | INT |
| @SupplierID | IN | INT |
| @QuantityReceived | IN | INT |
| @PurchaseOrderID | OUT | INT |
| @UpdatedStockLevel | OUT | INT |
| @StatusMessage | OUT | VARCHAR(255) |

**Validations:** Product exists · Supplier active · Quantity > 0 · Supplier authorized for category  
**Functions Called:** `fn_GetAvailableStock` → `fn_GetProductCategory`

---

### `usp_GetCustomerOrderSummary`
Generates order summary report for a customer within a date range.

| Parameter | Direction | Type |
|---|---|---|
| @CustomerID | IN | INT |
| @FromDate | IN | DATE |
| @ToDate | IN | DATE |
| @TotalOrders | OUT | INT |
| @TotalSpent | OUT | DECIMAL(10,2) |
| @StatusMessage | OUT | VARCHAR(255) |

**Validations:** Valid customer · FromDate ≤ ToDate · Date range ≤ 365 days  
**Functions Called:** `fn_IsValidCustomer` → `fn_CalculateOrderTotal`

---

## 🔗 Function Dependency Map

```
usp_PlaceOrder
    ├── fn_IsValidCustomer         → Customers
    ├── fn_GetAvailableStock       → Inventory
    ├── fn_GetCustomerDiscountRate → Customers
    └── fn_CalculateOrderTotal
            └── fn_GetCustomerDiscountRate → Customers
                        Orders, OrderItems

usp_GenerateInvoice
    ├── fn_CalculateOrderTotal     → Orders, OrderItems
    └── fn_CalculateTax            → TaxRates

usp_ProcessReturn
    ├── fn_IsValidCustomer         → Customers
    └── fn_CalculateOrderTotal     → Orders, OrderItems

usp_ProcessStockReplenishment
    ├── fn_GetAvailableStock       → Inventory
    └── fn_GetProductCategory      → Products, Categories

usp_GetCustomerOrderSummary
    ├── fn_IsValidCustomer         → Customers
    └── fn_CalculateOrderTotal     → Orders, OrderItems
```

---

## 🛠️ Technical Highlights

- ✅ **Scalar Functions** called inside Stored Procedures for modular logic
- ✅ **BEGIN TRANSACTION / COMMIT / ROLLBACK** for full data consistency
- ✅ **TRY...CATCH** error handling in every procedure
- ✅ **SCOPE_IDENTITY()** for safe identity capture after inserts
- ✅ **Computed Columns** — `LineTotal` in OrderItems, `TotalWithTax` in Invoices
- ✅ **CHECK Constraints** on all business-rule columns
- ✅ **CURSOR** for row-by-row inventory restore in `usp_ProcessReturn`
- ✅ **Layered Validations** — input → business rule → data integrity
- ✅ **Output Parameters** for all procedure results
- ✅ **ISNULL / NULL Guards** throughout all functions
- ✅ **Foreign Key Constraints** across all related tables
- ✅ **DATEDIFF** for 30-day return window enforcement
- ✅ **TOP 1 ORDER BY EffectiveDate DESC** for latest tax rate lookup

---

## 🚀 How to Run

### Prerequisites
- Microsoft SQL Server 2016 or later
- SQL Server Management Studio (SSMS) or Azure Data Studio

### Execution Order

```sql
-- Step 1: Create Database
CREATE DATABASE RetailDB;
USE RetailDB;

-- Step 2: Run Tables (in order)
-- Execute all scripts inside /tables/ folder in numbered order (01 → 12)

-- Step 3: Run Functions (in order)
-- fn_IsValidCustomer → fn_GetAvailableStock →
-- fn_GetCustomerDiscountRate → fn_CalculateOrderTotal →
-- fn_CalculateTax → fn_GetProductCategory

-- Step 4: Run Stored Procedures (any order)
-- usp_PlaceOrder, usp_GenerateInvoice,
-- usp_ProcessReturn, usp_ProcessStockReplenishment,
-- usp_GetCustomerOrderSummary

-- Step 5: Run Tests
-- Execute scripts in /tests/ folder
```

### Quick Test

```sql
-- Declare output variables
DECLARE @OrderID       INT;
DECLARE @TotalAmount   DECIMAL(10,2);
DECLARE @StatusMessage VARCHAR(255);

-- Place an order
EXEC usp_PlaceOrder
    @CustomerID    = 1,
    @ProductID     = 1,
    @Quantity      = 2,
    @OrderID       = @OrderID       OUTPUT,
    @TotalAmount   = @TotalAmount   OUTPUT,
    @StatusMessage = @StatusMessage OUTPUT;

SELECT @OrderID AS OrderID, @TotalAmount AS Total, @StatusMessage AS Message;
```

---

## 📊 Project Summary

| Object Type | Count |
|---|---|
| Tables | 12 |
| Scalar Functions | 6 |
| Stored Procedures | 5 |
| **Total DB Objects** | **23** |

---

## 👨‍💻 Author

Built as a complete end-to-end T-SQL retail domain project demonstrating:
- Normalized relational database design
- Modular stored procedure architecture
- Production-grade error handling and transaction management
- Real-world retail business logic implementation

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
