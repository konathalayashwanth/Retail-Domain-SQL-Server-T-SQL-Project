-- ============================================================
--   TABLE     : Returns
--   DOMAIN    : Retail
--   PURPOSE   : Stores return and refund records
--   DEPENDS ON: Orders, Customers
--   USED BY   : usp_ProcessReturn
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.Returns', 'U') IS NOT NULL
    DROP TABLE dbo.Returns;
GO

CREATE TABLE Returns
(
    ReturnID        INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    OrderID         INT             NOT NULL,
    CustomerID      INT             NOT NULL,
    ReturnDate      DATETIME        NOT NULL DEFAULT GETDATE(),
    ReturnReason    VARCHAR(255)    NOT NULL,
    RefundAmount    DECIMAL(10,2)   NOT NULL
                                    CONSTRAINT CHK_RefundAmount
                                    CHECK (RefundAmount >= 0),
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Processed'
                                    CONSTRAINT CHK_ReturnStatus
                                    CHECK (Status IN ('Processed', 'Rejected')),

    CONSTRAINT FK_Returns_Orders
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),

    CONSTRAINT FK_Returns_Customers
        FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
GO

-- ============================================================
-- Note: Returns are inserted via usp_ProcessReturn.
-- No sample data inserted here — run the procedure to test.
-- ============================================================
