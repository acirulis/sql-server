-- nodarbiba 01 (2023-11-14)

-- DATU TIPI
-- Piemērs, kāpēc FLOAT nedrīkst izmantot precīzos aprēķinos (Jāizmanto DECIMAL !)
GO
DECLARE @Value FLOAT(18) = 0.0;

WHILE @Value <> 10.0
    BEGIN
        PRINT @Value;
        SET @Value += 0.1;
    END;


-- CONSTRAINTS
-- šo funkciju var izmantot CHECK tipa CONSTRAINT, lai atļautu tikai derīgas e-pasta vērtības

CREATE FUNCTION dbo.IsValidEmail(@Email VARCHAR(255))
    RETURNS BIT
AS
BEGIN
    IF @Email LIKE '%@%.%' AND @Email NOT LIKE '%@%@%' AND @Email NOT LIKE '%..%'
        RETURN 1
    RETURN 0
END

-- TRIGGERS
-- piemērs, kurš CSP.Employees tabulā maina Email kolonnas vērtību, ja mainās Name kolonnas vērtība
USE CSP;
GO
CREATE TRIGGER UpdateEmail
    ON Employees
    AFTER UPDATE
    AS
BEGIN
    -- Check if the Name column is updated
    IF UPDATE(Name)
        BEGIN
            -- Update the Email column
            UPDATE Employees
            SET Email = INSERTED.Name + '@company.com'
            FROM Employees
                     INNER JOIN INSERTED ON Employees.Id = INSERTED.Id
        END
END


    -- FULL TEXT SEARCH

-- Piemērs, kā tabulā CSP.Articles darbojas full-text indekss.

    USE CSP;
    SELECT Articles.*, ft.rank
    from FREETEXTTABLE(Articles, body, 'latvija', LANGUAGE 'Latvian') ft
             inner join Articles on Articles.id = ft.[key]
    order by ft.rank desc

