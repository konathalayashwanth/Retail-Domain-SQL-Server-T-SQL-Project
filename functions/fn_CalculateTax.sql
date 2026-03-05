-- ============================================================
--   FUNCTION  : fn_CalculateTax
--   DOMAIN    : Retail
--   PURPOSE   : Calculates tax amount based on state code
--   INPUT     : @Amount    DECIMAL(10,2) — Order subtotal
--               @StateCode VARCHAR(5)   — State abbreviation
--   RETURNS   : DECIMAL(10,2) → Tax amount
--   TABLES    : TaxRates
--   CALLED BY : usp_GenerateInvoice
-- ============================================================

USE RetailDB;
GO

IF OBJECT_ID('dbo.fn_CalculateTax', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalculateTax;
GO

CREATE FUNCTION fn_CalculateTax
(
    @Amount       DECIMAL(10,2),    -- INPUT 1: Order subtotal amount
    @StateCode    VARCHAR(5)        -- INPUT 2: State code e.g. 'TX', 'CA'
)
RETURNS DECIMAL(10,2)               -- OUTPUT: Calculated tax amount
AS
BEGIN

    -- Step 1: Declare variables
    DECLARE @TaxRate      DECIMAL(5,2);
    DECLARE @TaxAmount    DECIMAL(10,2);

    -- Step 2: Validate Input — Amount must be positive
    IF @Amount IS NULL OR @Amount <= 0
        RETURN 0.00;

    -- Step 3: Validate Input — StateCode must not be NULL or empty
    IF @StateCode IS NULL OR LTRIM(RTRIM(@StateCode)) = ''
        RETURN 0.00;

    -- Step 4: Lookup TaxRate from TaxRates table
    --         Use TOP 1 with ORDER BY EffectiveDate DESC
    --         to always get the latest effective rate
    SELECT TOP 1
        @TaxRate = TaxRate
    FROM TaxRates
    WHERE StateCode     = @StateCode
    AND   EffectiveDate <= GETDATE()
    ORDER BY EffectiveDate DESC;

    -- Step 5: Default TaxRate to 0 if StateCode not found
    IF @TaxRate IS NULL
        SET @TaxRate = 0.00;

    -- Step 6: Calculate Tax Amount
    --         TaxAmount = Amount × (TaxRate / 100)
    SET @TaxAmount = @Amount * (@TaxRate / 100);

    -- Step 7: Return calculated tax amount
    RETURN @TaxAmount;

END;
GO

-- ============================================================
-- Test Cases
-- ============================================================
-- SELECT dbo.fn_CalculateTax(66500.00, 'TX')   → Expected: 5486.25 (8.25%)
-- SELECT dbo.fn_CalculateTax(54000.00, 'CA')   → Expected: 5535.00 (10.25%)
-- SELECT dbo.fn_CalculateTax(38250.00, 'NY')   → Expected: 3258.90 (8.52%)
-- SELECT dbo.fn_CalculateTax(50000.00, 'ZZ')   → Expected:    0.00 (Not Found)
-- SELECT dbo.fn_CalculateTax(NULL,     'TX')   → Expected:    0.00 (NULL Amount)
-- SELECT dbo.fn_CalculateTax(50000.00, NULL)   → Expected:    0.00 (NULL State)
-- SELECT dbo.fn_CalculateTax(0.00,     'TX')   → Expected:    0.00 (Zero Amount)
