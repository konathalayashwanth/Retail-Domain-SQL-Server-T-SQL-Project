-- ============================================================
--   TABLE     : Inventory
--   DOMAIN    : Retail
--   PURPOSE   : Tracks real-time stock levels per product
--   DEPENDS ON: Products
--   NOTE      : One record per product (UNIQUE on ProductID)
--   USED BY   : fn_GetAvailableStock
--               usp_PlaceOrder         (decrements stock)
--               usp_ProcessReturn      (restores stock)
--               usp_ProcessStockReplenishment (increments stock)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.Inventory', 'U') IS NOT NULL
    DROP TABLE dbo.Inventory;
GO

CREATE TABLE Inventory
(
    InventoryID         INT         NOT NULL PRIMARY KEY IDENTITY(1,1),
    ProductID           INT         NOT NULL UNIQUE,
    AvailableQuantity   INT         NOT NULL DEFAULT 0
                                    CONSTRAINT CHK_AvailableQuantity
                                    CHECK (AvailableQuantity >= 0),
    LastUpdated         DATETIME    NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Inventory_Products
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO

-- ============================================================
-- Sample Data — One row per product
-- ============================================================
INSERT INTO Inventory (ProductID, AvailableQuantity)
VALUES
(1,  50),    -- Laptop
(2,  80),    -- Mobile Phone
(3,  120),   -- Headphones
(4,  200),   -- T-Shirt
(5,  150),   -- Jeans
(6,  300),   -- Rice 5KG
(7,  400),   -- Cooking Oil 1L
(8,  30),    -- Office Chair
(9,  25),    -- Study Table
(10, 60),    -- Cricket Bat
(11, 90),    -- Football
(12, 5);     -- Old Model Phone (Discontinued — low stock)
GO
