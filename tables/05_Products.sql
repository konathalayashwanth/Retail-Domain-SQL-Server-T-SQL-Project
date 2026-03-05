-- ============================================================
--   TABLE     : Products
--   DOMAIN    : Retail
--   PURPOSE   : Stores product catalog with pricing
--   DEPENDS ON: Categories
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL
    DROP TABLE dbo.Products;
GO

CREATE TABLE Products
(
    ProductID       INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    ProductName     VARCHAR(150)    NOT NULL,
    CategoryID      INT             NOT NULL,
    UnitPrice       DECIMAL(10,2)   NOT NULL
                                    CONSTRAINT CHK_UnitPrice
                                    CHECK (UnitPrice > 0),
    ReorderLevel    INT             NOT NULL DEFAULT 10
                                    CONSTRAINT CHK_ReorderLevel
                                    CHECK (ReorderLevel >= 0),
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Active'
                                    CONSTRAINT CHK_ProductStatus
                                    CHECK (Status IN ('Active', 'Discontinued')),
    CreatedDate     DATETIME        NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Products_Categories
        FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);
GO

-- ============================================================
-- Sample Data
-- ============================================================
INSERT INTO Products
(ProductName,           CategoryID, UnitPrice,   ReorderLevel, Status)
VALUES
('Laptop',              1,          50000.00,    10,           'Active'),
('Mobile Phone',        1,          20000.00,    10,           'Active'),
('Headphones',          1,           5000.00,    15,           'Active'),
('T-Shirt',             2,            999.00,    20,           'Active'),
('Jeans',               2,           2500.00,    15,           'Active'),
('Rice 5KG',            3,            500.00,    50,           'Active'),
('Cooking Oil 1L',      3,            180.00,    50,           'Active'),
('Office Chair',        4,          15000.00,     5,           'Active'),
('Study Table',         4,          12000.00,     5,           'Active'),
('Cricket Bat',         5,           3500.00,    10,           'Active'),
('Football',            5,           1200.00,    10,           'Active'),
('Old Model Phone',     1,          10000.00,     5,           'Discontinued');
GO
