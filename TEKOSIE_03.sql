-- izveidojam unikalu finansu parskatu datu bāzi

-- Janis K
select *
from [ADP].[ur].[financial_statements] t
         inner join (select [legal_entity_registration_number], [year], max([id]) as MaxID
                     from [ADP].[ur].[financial_statements]

                     group by [legal_entity_registration_number], [year]) tm
                    on t.[legal_entity_registration_number] = tm.[legal_entity_registration_number] and
                       t.[year] = tm.[year] and t.id = tm.MaxID

-- ar Window funkcijam
GO
with ranked_fs as (select *,
                          ROW_NUMBER() over (partition by legal_entity_registration_number, year order by created_at desc) as RN
                   from ur.financial_statements)
select *
from ranked_fs
where RN = 1
;

-- SELECT INTO piemērs, uzreiz izveidojam jaunu tabulu ar tādu pašu struktūru, kā SELECT rezultāts
with cte as (select *,
                    ROW_NUMBER() over (partition by legal_entity_registration_number, year order by created_at desc) as RN
             from ur.financial_statements)
select [id]
     , [file_id]
     , [legal_entity_registration_number]
     , [source_schema]
     , [source_type]
     , [year]
     , [year_started_on]
     , [year_ended_on]
     , [employees]
     , [rounded_to_nearest]
     , [currency]
     , [created_at]
into ur.financial_statements_unique2
from cte
where RN = 1;



-- RECURSIVE
-- Piemērs (kā arī izmantojam Temporary Table, kas nesaglabājas db)
GO
CREATE TABLE #tbHierarchy
(
    Id       INT,
    [Name]   VARCHAR(20),
    ParentId INT
)

GO
INSERT INTO #tbHierarchy(Id, [Name], ParentId)
VALUES (1, 'Europe', NULL)
     , (2, 'Asia', NULL)
     , (3, 'Africa', NULL)
     , (4, 'France', 1)
     , (5, 'India', 2)
     , (6, 'China', 2)
     , (7, 'Zimbabwe', 3)
     , (8, 'Hong Kong', 6)
     , (9, 'Beijing', 6)
     , (10, 'Shanghai', 6)
     , (11, 'Chandigarh', 5)
     , (12, 'Mumbai', 5)
     , (13, 'Delhi', 5)
     , (14, 'Haryana', 5)
     , (15, 'Gurgaon', 14)
     , (16, 'Panchkula', 14)
     , (17, 'Paris', 4)
     , (18, 'Marseille', 4)
     , (19, 'Harare', 7)
     , (20, 'Bulawayo', 7);


SELECT *
FROM #tbHierarchy
;
WITH MyCTE
         AS
         (
             -- anchor
             SELECT Id,
                    [Name],
                    ParentId,
                    1                              AS [Level],
                    CAST(([Name]) AS VARCHAR(MAX)) AS Hierarchy
             FROM #tbHierarchy t1
             WHERE ParentId IS NULL

             UNION ALL
             --recursive member
             SELECT t2.id,
                    t2.[Name],
                    t2.ParentID,
                    M.[level] + 1                                        AS [Level],
                    CAST((M.Hierarchy + '->' + t2.Name) AS VARCHAR(MAX)) AS Hierarchy
             FROM #tbHierarchy AS t2
                      JOIN MyCTE AS M ON t2.ParentId = M.Id)

SELECT *
FROM MyCTE;

USE SQL_Study_2023;
--- NACE kodi rekursīvi
-- `rekursija` ar JOIN
select n1.kods,
       n2.kods,
       n3.kods,
       n4.kods,
       n1.kods + ' > ' + n2.kods + ' > ' + n3.kods + ' > ' + n4.kods
from web.nace_2 n1
         inner join web.nace_2 n2 on n2.vecaka_kods = n1.kods
         inner join web.nace_2 n3 on n3.vecaka_kods = n2.kods
         inner join web.nace_2 n4 on n4.vecaka_kods = n3.kods
;

-- rekursija
WITH nace_kodi as (select t1.kods,
                          t1.nosaukums,
                          vecaka_kods,
                          1                                  as level,
                          cast(t1.kods as varchar(max))      as k_h,
                          cast(t1.nosaukums as varchar(max)) as hierarhija
                   from web.nace_2 t1
                   where limenis = 0

                   UNION ALL

                   SELECT t2.kods,
                          t2.nosaukums,
                          t2.vecaka_kods,
                          nk.level + 1                                                 as level,
                          cast((nk.k_h + ' > ' + t2.kods) as varchar(max))             as k_h,
                          cast((nk.hierarhija + ' > ' + t2.nosaukums) as varchar(max)) as hierarhija
                   from web.nace_2 t2
                            inner join nace_kodi nk
                                       on t2.vecaka_kods = nk.kods)
select *
from nace_kodi
where level = 4


--------- APPLY
select value
from STRING_SPLIT('a, b, c', ',')

USE CSP;
SELECT *
from varda_dienas
         CROSS APPLY STRING_SPLIT(names, ',')


USE AdventureWorks2016;
GO
CREATE FUNCTION dbo.fn_GetAllEmployeeOfADepartment(@DeptID AS INT)
    RETURNS TABLE
        AS
        RETURN
            (
                select e.BusinessEntityID, ed.DepartmentID
                from HumanResources.Employee e
                         inner join HumanResources.EmployeeDepartmentHistory ed
                                    ON ed.BusinessEntityID = e.BusinessEntityID
                WHERE ed.EndDate IS NULL
                  AND ed.DepartmentID = @DeptID
            )
GO

SELECT *
FROM HumanResources.Department D
         CROSS APPLY dbo.fn_GetAllEmployeeOfADepartment(D.DepartmentID)
where D.DepartmentID = 1


-- WINDOW functions
USE CSP;
    select
        sales_employee,
        year,
        sale,
        LEAD(sale, 2) over (partition by sales_employee order by year) -- te var būt arī SUM, RANK, etc.
    from sales
    order by sales_employee, year

-- sagrupē Eksportu pēc uzņēmuma un valstīm, bet sakārto pēc tiem uzņēmumiem, kuriem kopējais eksports lielākais

-- Šīs ir pareizās kolonnas, bet nepareizi sakārtotas:
select sd.BizReg_Nos,
       g.[@geonomenclatureLabel],
       sum(vertiba) kopa_uz_valsti
from preces_IM_EX p
         left join geonomenclature g
                   on p.valsts = g.Country_code
         left join NMK_UUK NU on p.BizReg_UUK = NU.BizReg_UUK
         left join sur_dati sd on NU.BizReg_NMK = sd.BizReg_NMK
where P = 'E'
  and sd.BizReg_Nos is not null
group by sd.BizReg_Nos, g.[@geonomenclatureLabel]
order by BizReg_Nos
;

-- pareizās kolonnas, pareizi sakārtotas
with cte as (select sd.BizReg_Nos,
                    g.[@geonomenclatureLabel],
                    vertiba,
                    sum(vertiba) over ( partition by sd.BizReg_Nos) as vertiba_uznemumam
             from preces_IM_EX p
                      left join geonomenclature g
                                on p.valsts = g.Country_code
                      left join NMK_UUK NU on p.BizReg_UUK = NU.BizReg_UUK
                      left join sur_dati sd on NU.BizReg_NMK = sd.BizReg_NMK
             where P = 'E'
               and sd.BizReg_Nos is not null)
select BizReg_Nos,
       [@geonomenclatureLabel],
       sum(vertiba) as vertiba
from cte
group by vertiba_uznemumam, BizReg_Nos,
         [@geonomenclatureLabel]
order by vertiba_uznemumam desc, BizReg_Nos


-------- DATES

-- uzdevuma datu ģenerēšana ar RAND() funkcijas palīdzību
GO
DECLARE @randomDate DATE;
DECLARE @i INT = 0;
DECLARE @year INT;
DECLARE @month INT;
DECLARE @day INT;

WHILE @i < 10
BEGIN
    -- Generate a random date
    SET @randomDate = DATEADD(DAY, RAND() * 365, DATEADD(YEAR, -1 * RAND() *5, GETDATE()));

    -- Extract year, month, and day parts
    SET @year = YEAR(@randomDate);
    SET @month = MONTH(@randomDate);
    SET @day = DAY(@randomDate);

    -- Insert the random dates in the specified formats into the table
    INSERT INTO DateExamples (date1, date2, date3, date4)
    VALUES (
        CONVERT(VARCHAR(8), @randomDate, 112), -- YYYYMMDD
        FORMAT(@randomDate, 'dd/MM/yyyy'),     -- DD/MM/YYYY
        FORMAT(@randomDate, 'dd.MM.yy') + ' ' + FORMAT(CAST(RAND() * 24 AS INT), '00') + ':' + FORMAT(CAST(RAND() * 60 AS INT), '00'), -- DD.MM.YY HH:MM
        FORMAT(@randomDate, 'MM.dd')           -- MM.DD
    );

    SET @i = @i + 1;
END



-------- Konvertējam teksta vērtības uz DATE
SELECT
    date1,
    TRY_CONVERT(DATE, date1, 112) AS ConvertedColumn1,
    date2,
    TRY_CONVERT(DATE, date2, 103) AS ConvertedColumn2,
    date3,
    TRY_CONVERT(DATE, LEFT(date3, 8), 4) AS ConvertedColumn3,
    date4,
    TRY_CONVERT(DATE, CONCAT(YEAR(GETDATE()), '.', date4)) AS ConvertedColumn4
FROM DateExamples


--- https://www.sqlshack.com/sql-server-functions-for-converting-string-to-date/
--- CAST, CONVERT,

select parse('13/12/2019' as date USING 'lv-LV')


