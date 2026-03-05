-- ============================================================
--   TABLE     : Orders
--   DOMAIN    : Retail
--   PURPOSE   : Stores order header records
--   DEPENDS ON: Customers
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL
    DROP TABLE dbo.Orders;
GO

CREATE TABLE Orders
(
    OrderID             INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    CustomerID          INT             NOT NULL,
    OrderDate           DATETIME        NOT NULL DEFAULT GETDATE(),
    Status              VARCHAR(20)     NOT NULL DEFAULT 'Pending'
                                        CONSTRAINT CHK_OrderStatus
                                        CHECK (Status IN ('Pending', 'Confirmed',
                                                          'Invoiced', 'Delivered', 'Returned')),
    TotalAmount         DECIMAL(10,2)   NULL
                                        CONSTRAINT CHK_TotalAmount
                                        CHECK (TotalAmount >= 0),
    DiscountApplied     DECIMAL(5,2)    NOT NULL DEFAULT 0.00
                                        CONSTRAINT CHK_DiscountApplied
                                        CHECK (DiscountApplied >= 0 AND DiscountApplied <= 100),
    CreatedDate         DATETIME        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
GO

-- ============================================================
-- Note: Orders are inserted via usp_PlaceOrder procedure.
-- Sample data below is for direct testing only.
-- ============================================================
INSERT INTO Orders
(CustomerID, OrderDate,   Status,      TotalAmount, DiscountApplied)
VALUES
(1,          GETDATE(),   'Confirmed', 0.00,        5.00),
(2,          GETDATE(),   'Confirmed', 0.00,        10.00),
(3,          GETDATE(),   'Confirmed', 0.00,        15.00);
GO
