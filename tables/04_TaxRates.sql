-- ============================================================
--   TABLE     : TaxRates
--   DOMAIN    : Retail
--   PURPOSE   : Stores state-wise tax rates
--   DEPENDS ON: None (Parent Table)
--   USED BY   : fn_CalculateTax
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.TaxRates', 'U') IS NOT NULL
    DROP TABLE dbo.TaxRates;
GO

CREATE TABLE TaxRates
(
    TaxRateID       INT             NOT NULL PRIMARY KEY IDENTITY(1,1),
    StateCode       VARCHAR(5)      NOT NULL UNIQUE,
    StateName       VARCHAR(100)    NOT NULL,
    TaxRate         DECIMAL(5,2)    NOT NULL
                                    CONSTRAINT CHK_TaxRate
                                    CHECK (TaxRate >= 0 AND TaxRate <= 100),
    EffectiveDate   DATE            NOT NULL
);
GO

-- ============================================================
-- Sample Data
-- ============================================================
INSERT INTO TaxRates
(StateCode, StateName,      TaxRate, EffectiveDate)
VALUES
('TX',  'Texas',            8.25,   '2023-01-01'),
('CA',  'California',       10.25,  '2023-01-01'),
('NY',  'New York',          8.52,  '2023-01-01'),
('FL',  'Florida',           6.00,  '2023-01-01'),
('WA',  'Washington',       10.40,  '2023-01-01'),
('NV',  'Nevada',            8.38,  '2023-01-01'),
('IL',  'Illinois',         10.00,  '2023-01-01'),
('GA',  'Georgia',           7.00,  '2023-01-01');
GO
