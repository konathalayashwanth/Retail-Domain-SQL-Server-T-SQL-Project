-- ============================================================
--   TABLE     : OrderItems
--   DOMAIN    : Retail
--   PURPOSE   : Stores order line items (child of Orders)
--   DEPENDS ON: Orders, Products
--   NOTE      : LineTotal is a PERSISTED computed column
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.OrderItems', 'U') IS NOT NULL
    DROP TABLE dbo.OrderItems;
GO

CREATE TABLE OrderItems
(
    OrderItemID     INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    OrderID         INT             NOT NULL,
    ProductID       INT             NOT NULL,
    Quantity        INT             NOT NULL
                                    CONSTRAINT CHK_OI_Quantity
                                    CHECK (Quantity > 0),
    UnitPrice       DECIMAL(10,2)   NOT NULL
                                    CONSTRAINT CHK_OI_UnitPrice
                                    CHECK (UnitPrice > 0),
    LineTotal       AS (Quantity * UnitPrice) PERSISTED,   -- Computed Column

    CONSTRAINT FK_OrderItems_Orders
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),

    CONSTRAINT FK_OrderItems_Products
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO

-- ============================================================
-- Note: OrderItems are inserted via usp_PlaceOrder procedure.
-- Sample data below links to the 3 sample Orders inserted.
-- ============================================================

-- Order 1: CustomerID=1 (Silver 5%) → Laptop x1 + Mobile x1 = 70,000
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES
(1, 1, 1, 50000.00),   -- Laptop      x1 = 50,000
(1, 2, 1, 20000.00);   -- Mobile      x1 = 20,000

-- Order 2: CustomerID=2 (Gold 10%) → Laptop x1 + Headphones x2 = 60,000
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES
(2, 1, 1, 50000.00),   -- Laptop      x1 = 50,000
(2, 3, 2,  5000.00);   -- Headphones  x2 = 10,000

-- Order 3: CustomerID=3 (Platinum 15%) → Mobile x2 + Headphones x1 = 45,000
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES
(3, 2, 2, 20000.00),   -- Mobile      x2 = 40,000
(3, 3, 1,  5000.00);   -- Headphones  x1 =  5,000
GO
