USE CSP;
GO;
-- select * from CSP_USERS
DECLARE @Id INT = 3;
DECLARE @Name NVARCHAR(100);
DECLARE @LastLetter NVARCHAR(1);
DECLARE @NameForm NVARCHAR(100);
DECLARE user_cursor CURSOR FOR
    SELECT Id, Fname
    FROM CSP_USERS;
OPEN user_cursor;
FETCH NEXT FROM user_cursor INTO @Id, @Name;

WHILE @@fetch_status = 0
    BEGIN
        PRINT @Id;
        SET @LastLetter = RIGHT(@Name, 1)
        IF @LastLetter in ('s', 'o', 'š')
            BEGIN
                SET @NameForm = @Name;
                if @LastLetter <> 'o'
                    BEGIN
                        SET @NameForm = LEFT(@Name, LEN(@Name) - 1)
                    END
                print (N'Sveiks, ' + @NameForm + N'!')
            end
        ELSE
            begin
                print (N'Sveika, ' + @Name + N'!')
            end
        FETCH NEXT FROM user_cursor INTO @Id, @Name;
    END
CLOSE user_cursor;
DEALLOCATE user_cursor;
GO
-- Lekcijas uzdevums
-- Trūkstošie periodi

WITH CTE1 AS (select VRN,
                     PERIODS,
                     LAG(PERIODS, 1) OVER (partition by VRN order by PERIODS) PERIODS_IEPR
              from goaldatums_2023gads)
   , CTE2 AS (SELECT VRN,
                     CAST(PERIODS + '01' AS DATE)      as PERIODS_DATE,
                     CAST(PERIODS_IEPR + '01' AS DATE) as PERIODS_IEPR_DATE
              FROM CTE1)

select VRN,
       PERIODS_DATE,
       PERIODS_IEPR_DATE,
       DATEDIFF(MONTH, PERIODS_IEPR_DATE, PERIODS_DATE) AS STARPIBA
FROM CTE2
WHERE DATEDIFF(MONTH, PERIODS_IEPR_DATE, PERIODS_DATE) > 1
ORDER BY STARPIBA DESC


DECLARE @sales_employee VARCHAR(100);
DECLARE @totalSales INT;
DECLARE @salesTarget INT = 1200;

-- Declare the cursor
DECLARE salesCursor CURSOR FOR
    SELECT sales_employee, SUM(sale) as totalSales
    FROM sales
    GROUP BY sales_employee;

-- Open the cursor
OPEN salesCursor;

-- Fetch the first row from the cursor
FETCH NEXT FROM salesCursor INTO @sales_employee, @totalSales;

-- Loop through the rows
WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @totalSales >= @salesTarget
            PRINT @sales_employee + ' has reached the sales target with total sales of ' +
                  CAST(@totalSales AS VARCHAR(10));
        ELSE
            PRINT @sales_employee + ' has not reached the sales target with total sales of ' +
                  CAST(@totalSales AS VARCHAR(10));

        -- Fetch the next row from the cursor
        FETCH NEXT FROM salesCursor INTO @sales_employee, @totalSales;
    END

-- Close and deallocate the cursor
CLOSE salesCursor;
DEALLOCATE salesCursor;


-- LOOP batch update
-- select top 3 * from sales;

DECLARE @BatchSize INT = 100; -- Number of rows to update in each batch
DECLARE @RowsUpdated INT;

SET @RowsUpdated = @BatchSize; -- Initialize to enter the loop

WHILE @RowsUpdated = @BatchSize
    BEGIN
        UPDATE TOP (@BatchSize) sales
        SET YourColumn = 'NewValue'
        WHERE YourColumn IS NULL;

        SET @RowsUpdated = @@ROWCOUNT; -- Get the number of rows updated
    END

-- Count through table
GO
DECLARE @TotalSales INT = 0;
DECLARE @CurrentID INT = 1;
DECLARE @MaxID INT;

SELECT @MaxID = MAX(ID)
FROM SalesTable;

WHILE @CurrentID <= @MaxID
    BEGIN
        DECLARE @SaleAmount INT;
        SELECT @SaleAmount = SaleAmount FROM SalesTable WHERE ID = @CurrentID;

        IF @SaleAmount IS NOT NULL
            SET @TotalSales = @TotalSales + @SaleAmount;

        SET @CurrentID = @CurrentID + 1;
    END

PRINT 'Total Sales: ' + CAST(@TotalSales AS VARCHAR(10));


-- STORED PROCEDURES

CREATE PROCEDURE GetEmployeeDetails @EmployeeID INT
AS
BEGIN
    SELECT * FROM Employees WHERE Id = @EmployeeID;
END
    EXEC GetEmployeeDetails @EmployeeID = 4;


    USE AdventureWorks2016
GO



select Id,
       DisplayName,
       FName,
       IIF(RIGHT(FName, 1) = 'š', 'Beidzas ar š', 'Nebeidzas ar š')
from CSP_USERS
WHERE Id = 275


--- MD 1

-- Dota sekojoša procedūra.
-- Izmēģināt to
-- un pārveidot tā, lai visus 3 laukos meklētu arī tad, ja meklējamā frāze atbilst daļēji (LIKE).

CREATE PROCEDURE SearchEmployees @Name NVARCHAR(100) = NULL,
                                 @Email NVARCHAR(100) = NULL,
                                 @Department NVARCHAR(100) = NULL
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(MAX);

    -- Start building the dynamic SQL query
    SET @SQL = N'SELECT * FROM Employees WHERE 1 = 1';

    -- Append conditions based on input parameters
    IF @Name IS NOT NULL
        SET @SQL = @SQL + N' AND Name = @Name';

    IF @Email IS NOT NULL
        SET @SQL = @SQL + N' AND Email = @Email';

    IF @Department IS NOT NULL
        SET @SQL = @SQL + N' AND Department = @Department';

    -- Define the parameters for the dynamic SQL
    SET @Params = N'@Name NVARCHAR(100), @Email NVARCHAR(100), @Department NVARCHAR(100)';

    -- Execute the dynamic SQL
    EXEC sp_executesql @SQL, @Params,
         @Name = @Name,
         @Email = @Email,
         @Department = @Department;
END
    EXEC SearchEmployees @Name = 'ABC 15'


-- MD2

-- Uzrakstīt SQL funkciju, kura pārveido jebkuru vārdu tā, lai pirmais burts būtu lielais,
-- nākamais mazais, tad atkal lielais, utt.
-- Piem: grāmata -> GrĀmAtA
-- Piem: Darbs -> DaRbS
-- Ideja: izmantot WHILE ciklu un @n INT mainīgo, kas iet no 1 līdz vārda garumam.

-- MD3

-- Uzrakstīt SQL funkciju, kura no CSP.dbo.goaldatums_2023gads tabulas saņem parametru VRN (piemēram 0x51C3E145C2A83472E19C3612609018094C788F44A96860E5817C5E8076680FCA)
-- un atgriež, cik KM ir reģistrētais nobraukums (lielākais - mazākais Odometra rādījums)


-- MD4

-- Uzrakstīt procedūru, kura kā ieejas parametru saņem UUK vērtību no tea.VDVV_2017 tabulas un uz ekrāna
-- ar PRINT palīdzību izdrukā informāciju par objektu, apvienojot to ar web.nace_2 informāciju:
-- Piemērs:
-- Zobārstniecības kabinets, kas atrodas Talsu iela 31, Ventspils, LV-3602, nodarbojas ar "Zobārstu prakse"

-- MD4.2
-- Pārveidot šo uzdevumu kā Batch Skriptu, kurš ar CURSOR palīdzību izvada šo informāciju visiem tabulas ierakstiem
-- kas atrodas Rīgā. Kā noteikt Rīgu?



