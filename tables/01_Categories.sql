-- ============================================================
--   TABLE     : Categories
--   DOMAIN    : Retail
--   PURPOSE   : Stores product category master data
--   DEPENDS ON: None (Parent Table)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL
    DROP TABLE dbo.Categories;
GO

CREATE TABLE Categories
(
    CategoryID      INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    CategoryName    VARCHAR(50)     NOT NULL UNIQUE,
    Description     VARCHAR(255)    NULL,
    CreatedDate     DATETIME        NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- Sample Data
-- ============================================================
INSERT INTO Categories (CategoryName, Description)
VALUES
('Electronics',  'Electronic gadgets and devices'),
('Clothing',     'Apparel and fashion items'),
('Groceries',    'Daily essential food items'),
('Furniture',    'Home and office furniture'),
('Sports',       'Sports and fitness equipment');
GO
