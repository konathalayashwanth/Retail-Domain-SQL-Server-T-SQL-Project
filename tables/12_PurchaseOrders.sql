-- ============================================================
--   TABLE     : PurchaseOrders
--   DOMAIN    : Retail
--   PURPOSE   : Stores stock replenishment records
--   DEPENDS ON: Products, Suppliers
--   USED BY   : usp_ProcessStockReplenishment
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.PurchaseOrders', 'U') IS NOT NULL
    DROP TABLE dbo.PurchaseOrders;
GO

CREATE TABLE PurchaseOrders
(
    PurchaseOrderID     INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    ProductID           INT             NOT NULL,
    SupplierID          INT             NOT NULL,
    QuantityReceived    INT             NOT NULL
                                        CONSTRAINT CHK_QuantityReceived
                                        CHECK (QuantityReceived > 0),
    PurchaseDate        DATETIME        NOT NULL DEFAULT GETDATE(),
    Status              VARCHAR(20)     NOT NULL DEFAULT 'Received'
                                        CONSTRAINT CHK_POStatus
                                        CHECK (Status IN ('Received', 'Pending')),

    CONSTRAINT FK_PurchaseOrders_Products
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID),

    CONSTRAINT FK_PurchaseOrders_Suppliers
        FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
GO

-- ============================================================
-- Note: PurchaseOrders are inserted via usp_ProcessStockReplenishment.
-- No sample data inserted here — run the procedure to test.
-- ============================================================
