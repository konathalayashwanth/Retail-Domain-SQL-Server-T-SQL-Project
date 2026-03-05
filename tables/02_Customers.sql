-- ============================================================
--   TABLE     : Customers
--   DOMAIN    : Retail
--   PURPOSE   : Stores customer master data with tier info
--   DEPENDS ON: None (Parent Table)
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL
    DROP TABLE dbo.Customers;
GO

CREATE TABLE Customers
(
    CustomerID      INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    FirstName       VARCHAR(100)    NOT NULL,
    LastName        VARCHAR(100)    NOT NULL,
    Email           VARCHAR(150)    NOT NULL UNIQUE,
    Phone           VARCHAR(15)     NULL,
    StateCode       VARCHAR(5)      NOT NULL,
    CustomerTier    VARCHAR(20)     NOT NULL DEFAULT 'Silver'
                                    CONSTRAINT CHK_CustomerTier
                                    CHECK (CustomerTier IN ('Silver', 'Gold', 'Platinum')),
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Active'
                                    CONSTRAINT CHK_CustomerStatus
                                    CHECK (Status IN ('Active', 'Inactive')),
    CreatedDate     DATETIME        NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- Sample Data
-- ============================================================
INSERT INTO Customers
(FirstName, LastName, Email,                   Phone,        StateCode, CustomerTier, Status)
VALUES
('Rajesh',  'Kumar',  'rajesh@gmail.com',      '9876543210', 'TX',      'Silver',     'Active'),
('Priya',   'Sharma', 'priya@gmail.com',       '9876543211', 'CA',      'Gold',       'Active'),
('Anil',    'Verma',  'anil@gmail.com',        '9876543212', 'NY',      'Platinum',   'Active'),
('Sneha',   'Rao',    'sneha@gmail.com',       '9876543213', 'FL',      'Gold',       'Inactive'),
('Kiran',   'Patel',  'kiran@gmail.com',       '9876543214', 'WA',      'Silver',     'Active');
GO
