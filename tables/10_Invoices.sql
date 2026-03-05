-- ============================================================
--   TABLE     : Invoices
--   DOMAIN    : Retail
--   PURPOSE   : Stores invoice records (one per order)
--   DEPENDS ON: Orders
--   NOTE      : TotalWithTax is a PERSISTED computed column
--               One invoice per order (UNIQUE on OrderID)
--   USED BY   : usp_GenerateInvoice
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.Invoices', 'U') IS NOT NULL
    DROP TABLE dbo.Invoices;
GO

CREATE TABLE Invoices
(
    InvoiceID       INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    OrderID         INT             NOT NULL UNIQUE,
    InvoiceDate     DATETIME        NOT NULL DEFAULT GETDATE(),
    SubTotal        DECIMAL(10,2)   NOT NULL
                                    CONSTRAINT CHK_SubTotal
                                    CHECK (SubTotal >= 0),
    TaxAmount       DECIMAL(10,2)   NOT NULL
                                    CONSTRAINT CHK_TaxAmount
                                    CHECK (TaxAmount >= 0),
    TotalWithTax    AS (SubTotal + TaxAmount) PERSISTED,   -- Computed Column
    StateCode       VARCHAR(5)      NOT NULL,

    CONSTRAINT FK_Invoices_Orders
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);
GO

-- ============================================================
-- Note: Invoices are inserted via usp_GenerateInvoice.
-- No sample data inserted here — run the procedure to test.
-- ============================================================
