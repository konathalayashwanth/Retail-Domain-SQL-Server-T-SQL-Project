-- ============================================================
--   TABLE     : Suppliers
--   DOMAIN    : Retail
--   PURPOSE   : Stores supplier master data
--   DEPENDS ON: None (Parent Table)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.Suppliers', 'U') IS NOT NULL
    DROP TABLE dbo.Suppliers;
GO

CREATE TABLE Suppliers
(
    SupplierID      INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    SupplierName    VARCHAR(150)    NOT NULL,
    ContactEmail    VARCHAR(150)    NULL,
    Phone           VARCHAR(15)     NULL,
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Active'
                                    CONSTRAINT CHK_SupplierStatus
                                    CHECK (Status IN ('Active', 'Inactive')),
    CreatedDate     DATETIME        NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- Sample Data
-- ============================================================
INSERT INTO Suppliers
(SupplierName,          ContactEmail,               Phone,        Status)
VALUES
('TechWorld Pvt Ltd',   'tech@techworld.com',       '9111000001', 'Active'),
('Fashion Hub Ltd',     'supply@fashionhub.com',    '9111000002', 'Active'),
('FreshMart Co',        'orders@freshmart.com',     '9111000003', 'Active'),
('HomeDecor Suppliers', 'info@homedecor.com',       '9111000004', 'Active'),
('SportZone Traders',   'sales@sportzone.com',      '9111000005', 'Inactive');
GO
