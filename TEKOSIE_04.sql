-- Ar DATEDIFF palīdzību varam iegūt mēnešu, gadu VAI dienu skaitu starp diviem datumiem
-- Uzdevums uzrakstīt vaicājumu, lai iegūtu pilnu intervālu starp diviem datumiem
-- piemēram, nevis 25 mēneši (ko iegūt ir vienkārši ar DATEDIFF izmantošanu), bet 2 gadi un 1 mēnesis un 0 dienas.
-- Izmantojam tabulu DateExamples un jebkuru kolonnu kā izejas datus, salīdzinot ar šodienu (GETDATE)

select DATEDIFF(MONTH, CAST('2020-11-25' AS DATE), GETDATE())

SELECT id,
       CONVERT(DATE, date1, 112) as date1,
       CASE
           WHEN DATEADD(YEAR, DATEDIFF(YEAR, CONVERT(DATE, date1, 112), GETDATE()), CONVERT(DATE, date1, 112)) >
                GETDATE()
               THEN DATEDIFF(YEAR, CONVERT(DATE, date1, 112), GETDATE()) - 1
           ELSE DATEDIFF(YEAR, CONVERT(DATE, date1, 112), GETDATE())
           END                   AS YearsDifference,
       CASE
           WHEN DATEADD(MONTH, DATEDIFF(MONTH, CONVERT(DATE, date1, 112), GETDATE()), CONVERT(DATE, date1, 112)) >
                GETDATE()
               THEN DATEDIFF(MONTH, CONVERT(DATE, date1, 112), GETDATE()) - 1
           ELSE DATEDIFF(MONTH, CONVERT(DATE, date1, 112), GETDATE())
           END % 12              AS MonthsDifference,
       DATEDIFF(DAY,
                DATEADD(MONTH,
                        CASE
                            WHEN DATEADD(MONTH, DATEDIFF(MONTH, CONVERT(DATE, date1, 112), GETDATE()),
                                         CONVERT(DATE, date1, 112)) > GETDATE()
                                THEN DATEDIFF(MONTH, CONVERT(DATE, date1, 112), GETDATE()) - 1
                            ELSE DATEDIFF(MONTH, CONVERT(DATE, date1, 112), GETDATE())
                            END
                    , CONVERT(DATE, date1, 112)),
                GETDATE())       AS DaysDifference
FROM DateExamples;


select DATEDIFF(MONTH, CAST('2020-11-25' AS DATE), GETDATE())


---
-- Median aprēķināšana

use adp;
with data as (select [Adreses pieraksts], Pilsēta, cast(replace([Darījuma summa, EUR], ',', '.') as float) as summa
              from TG_CSV_2022)
select Pilsēta, avg(summa) as vid_pilseta
from data
group by Pilsēta;


with data as (select [Adreses pieraksts], Pilsēta, cast(replace([Darījuma summa, EUR], ',', '.') as float) as summa
              from TG_CSV_2022)
select distinct Pilsēta,
                PERCENTILE_CONT(0.5) within group ( order by summa) over (partition by Pilsēta) as median_pilseta
from data;


with data as (select [Adreses pieraksts], Pilsēta, cast(replace([Darījuma summa, EUR], ',', '.') as float) as summa
              from TG_CSV_2022)
select *
from data
where Pilsēta = 'Viļāni'
order by summa asc


-- https://www.sqlshack.com/using-sql-server-cursors-advantages-and-disadvantages/

-- TSQL programming
-- Variables
-- #1
USE SQL_Study_2023;
GO
DECLARE @StartDate DATE, @EndDate DATE;
SET @EndDate = CAST(GETDATE() AS DATE); -- Sets EndDate to today's date
SET @StartDate = DATEADD(YEAR, -1, @EndDate); -- Sets StartDate to one year before EndDate

SELECT *
FROM goaldatums_2023gads
WHERE TA_DATUMS BETWEEN @StartDate AND @EndDate;
GO

-- #2
SELECT izglitibas_iestade, MAX(vid_ienakumi) as m
FROM SQL_Study_2023.csp_abs_monit.Augstskolu_absolventu_monitorings_2017_2020_absolventi_2021_dati_pseido
GROUP By izglitibas_iestade
order by m desc

DECLARE @iestade VARCHAR(max);
DECLARE @MaxVidIenakumi DECIMAL(10, 2);
SELECT @iestade = izglitibas_iestade, @MaxVidIenakumi = MAX(vid_ienakumi)
FROM SQL_Study_2023.csp_abs_monit.Augstskolu_absolventu_monitorings_2017_2020_absolventi_2021_dati_pseido
GROUP By izglitibas_iestade
order by MAX(vid_ienakumi) asc;
PRINT 'Vislielākie vidējie ienākumi';
PRINT 'Izglītības iestādē ' + @iestade + ' lielākie reģistrētie vidējie ienākumi ir ' +
      CAST(@MaxVidIenakumi AS NVARCHAR(20));
GO

-- IF ELSE
IF DATENAME(weekday, GETDATE()) IN (N'Saturday', N'Sunday')
    PRINT 'Weekend';
ELSE
    PRINT 'Weekday';

-- #1
-- Darbiniekam ar vārdu Alice, noteikt, vai viņa ir sasniegusi
-- pārdošanas mērķi 1000 EUR apmērā.
-- Uz ekrāna ar PRINT izvadīt atbildi - "Alice ir sasniegusi savu mērķi 1000 EUR, parsniedzot to par <<<>> EUR"
-- vai arī "Alice līdz mērķa sasniegšanai pietrūkst <<>> EUR"

USE CSP;
GO
DECLARE @EmployeeID VARCHAR(20) = 'Alice'; -- Izvēlamies darbinieku
DECLARE @SalesTarget DECIMAL(10, 2) = 1000.00;
DECLARE @TotalSales DECIMAL(10, 2);

SELECT @TotalSales = SUM(sale)
FROM sales
WHERE sales_employee = @EmployeeID;

IF @TotalSales >= @SalesTarget
    BEGIN
        PRINT @EmployeeID + ' ir sasniegusi savu mērķi ' + CAST(@SalesTarget as varchar) + ' pārsniedzot to par ' +
              CAST((@TotalSales - @SalesTarget) as varchar);
--         UPDATE sales SET Status = 'Target Achieved' WHERE EmployeeID = @EmployeeID;
    END
ELSE
    BEGIN
        PRINT @EmployeeID + ' līdz mērķa ' + CAST(@SalesTarget as varchar) + ' sasniegšanai pietrūkst ' +
              CAST((@SalesTarget - @TotalSales) as varchar);
--         UPDATE sales SET Status = 'Target Not Achieved' WHERE EmployeeID = @EmployeeID;
    END
GO

-- #2
DECLARE @PurchaseAmount DECIMAL(10, 2) = 500.00; -- Example Purchase Amount
DECLARE @DiscountRate DECIMAL(5, 2);

IF @PurchaseAmount > 1000
    SET @DiscountRate = 0.15 -- 15% discount
ELSE
    IF @PurchaseAmount > 500
        SET @DiscountRate = 0.10 -- 10% discount
    ELSE
        SET @DiscountRate = 0.05 -- 5% discount

PRINT 'The discount rate is: ' + CAST(@DiscountRate AS NVARCHAR(10));

-- #3

DECLARE @ProductID INT = 101; -- Example Product ID
DECLARE @ProductName NVARCHAR(100) = 'New Product';

IF NOT EXISTS(SELECT 1
              FROM Products
              WHERE ProductID = @ProductID)
    BEGIN
        INSERT INTO Products (ProductID, ProductName) VALUES (@ProductID, @ProductName);
        PRINT 'Product added successfully.';
    END
ELSE
    PRINT 'Product already exists.';

USE SQL_Study_2023;
GO
-- Mājas darbs #1
-- Window  funkciju lietošana
-- Tabulā goaldatums_2023gads atlasīt auto reģistrācijas numuru (VRN), periodu (PERIODS) un īpašnieku (PERSONAS_UZNEMUMA_KODS).
-- ar LAG vai LAG funkcijas palīdzību pievienot iepriekšējā perioda īpašnieku katram numuram
-- un atlasīt tos, kur īpašnieki nesakrīt, tātad pieņemot, ka notikusi īpašnieka maiņa.

WITH CTE1 AS (select VRN,
                     PERIODS,
                     PERSONAS_UZNEMUMA_KODS,
                     LAG(PERSONAS_UZNEMUMA_KODS, 1) OVER (partition by VRN order by PERIODS) LM_PK
              from goaldatums_2023gads)
select *
from CTE1
WHERE PERSONAS_UZNEMUMA_KODS <> LM_PK

-- Mājas darbs #2
-- Tabulā Data_Export_CSP_2023gads atlasīt auto reģistrācijas numuru (VRN), periodu (PERIODS) un licences darbības termiņu (datums_lidz)
-- Katram pārim (auto + periods) atlasīt to licenci, kurai vislielākais derīguma  termiņš, ja pārī ir vairākas licences.

USE CSP;
GO
select *
FROM [CSP].dbo.CSP_USERS

-- Mājas darbs #3
-- Tabulā [CSP].dbo.CSP_USERS ir lietotāju dati.
-- Izveidot skriptu (Batch script), kurš atbilstoši mainīgā EmployeeID vērtībai paņem vienu ierakstu no tabulas
-- un izveido (ar PRINT izvada uz ekrāna) pareizu uzrunas formu, piemēram:
-- Sveika, Aija
-- Sveiks, Kaspars
-- Sveika, Ieva
-- Sveiks, Pēteris
-- bonusa uzdevums - pielāgot arī personvārdu, piemēram, Sveiks, Pēteri!
-- Izmantot IF/ELSE un dažādas teksta apstrādes funkcijas.
-- nākošajā nodarbībā mācīsimies to izdarīt visiem tabulas ierakstiem uzreiz ar WHILE un CURSOR - ja kāds vēlas iet uz priekšu ātrāk.


USE CSP;
GO;
-- select * from CSP_USERS
DECLARE @Id INT = 3;
DECLARE @Name VARCHAR(100);
DECLARE @LastLetter VARCHAR(1);
DECLARE @NameForm VARCHAR(100);
DECLARE user_cursor CURSOR FOR
    SELECT top 20 Fname
    FROM CSP_USERS;
OPEN user_cursor;
FETCH NEXT FROM user_cursor INTO @Name;

WHILE @@fetch_status = 0
    BEGIN
        --         PRINT @Name;
        SET @LastLetter = RIGHT(@Name, 1)
        IF @LastLetter in ('s', 'o')
            BEGIN
                SET @NameForm = @Name;
                if @LastLetter <> 'o'
                    BEGIN
                        SET @NameForm = LEFT(@Name, LEN(@Name) - 1)
                    END
                print ('Sveiks, ' + @NameForm + '!')
            end
        ELSE
            begin
                print ('Sveika, ' + @Name + '!')
            end
        FETCH NEXT FROM user_cursor INTO @Name;
    END
CLOSE user_cursor;
DEALLOCATE user_cursor;
GO;



-- Mājas darbs #4
-- Tabulā ADP.ur.financial_statements_unique un saistītajās (income_satements, balance_sheets, u.c.) ir uzņēmuma finanšu pārskata dati.
-- Mainīgajā registrationNumber uzstādot reģistrācijas numuru
-- izveidot SQL skriptu (batch script), kurš veic uzņēmuma analīzi balstoties uz
-- https://www.linkedin.com/pulse/10-svar%C4%ABgi-r%C4%81d%C4%ABt%C4%81ji-uz%C5%86%C4%93muma-vad%C4%ABt%C4%81jam-capitalia-finance/
-- norādītājiem kritērijiem (pietiek izvēlēties 2-3, nav obligāti visi)
-- Tātad pēc reģistrācijas numura norādīšanas un skripta izpildes uz ekrāna ar PRINT palīdzību
-- tiek izvadīti dažādi viena uzņēmuma darbības rādītāji
-- bonuss - pievienot skaidrojošus komentārus, piemēram, "Pievērst uzmanību negatīvām pašu kapitālam", vai tamlīdzīgi.
