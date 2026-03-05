-- ============================================================
--   TABLE     : SupplierCategories
--   DOMAIN    : Retail
--   PURPOSE   : Junction table — Supplier to Category
--               authorization mapping
--   DEPENDS ON: Suppliers, Categories
--   USED BY   : usp_ProcessStockReplenishment
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.SupplierCategories', 'U') IS NOT NULL
    DROP TABLE dbo.SupplierCategories;
GO

CREATE TABLE SupplierCategories
(
    SupplierCategoryID  INT         NOT NULL PRIMARY KEY IDENTITY(1,1),
    SupplierID          INT         NOT NULL,
    CategoryID          INT         NOT NULL,

    CONSTRAINT FK_SupplierCategories_Suppliers
        FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),

    CONSTRAINT FK_SupplierCategories_Categories
        FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),

    -- Prevent duplicate supplier-category combinations
    CONSTRAINT UQ_SupplierCategory
        UNIQUE (SupplierID, CategoryID)
);
GO

-- ============================================================
-- Sample Data
-- SupplierID 1 = TechWorld     → Electronics (CategoryID 1)
-- SupplierID 2 = Fashion Hub   → Clothing    (CategoryID 2)
-- SupplierID 3 = FreshMart     → Groceries   (CategoryID 3)
-- SupplierID 4 = HomeDecor     → Furniture   (CategoryID 4)
-- SupplierID 5 = SportZone     → Sports      (CategoryID 5)
-- ============================================================
INSERT INTO SupplierCategories (SupplierID, CategoryID)
VALUES
(1, 1),   -- TechWorld   → Electronics
(2, 2),   -- Fashion Hub → Clothing
(3, 3),   -- FreshMart   → Groceries
(4, 4),   -- HomeDecor   → Furniture
(5, 5);   -- SportZone   → Sports
GO
