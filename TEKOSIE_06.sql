--- MD 1

-- Dota sekojoša procedūra.
-- Izmēģināt to (varat mainīt procedūras nosaukumu un pievienot datu bāzē kā savējo)
-- un pārveidot tā, lai visus 3 laukos meklētu arī tad, ja meklējamā frāze atbilst daļēji (LIKE).
GO
CREATE PROCEDURE SearchEmployees @Name NVARCHAR(100) = NULL,
                                 @Email NVARCHAR(100) = NULL,
                                 @Department NVARCHAR(100) = NULL
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(MAX);
    SET @SQL = N'SELECT * FROM Employees WHERE 1 = 1';
    IF @Name IS NOT NULL
        BEGIN
            SET @Name = '%' + @Name + '%'
            SET @SQL = @SQL + N' AND Name LIKE @Name';
        END
    IF @Email IS NOT NULL
        BEGIN
            SET @Email = '%' + @Email + '%'
            SET @SQL = @SQL + N' AND Email LIKE @Email';
        END
    IF @Department IS NOT NULL
        BEGIN
            SET @Department = '%' + @Department + '%'
            SET @SQL = @SQL + N' AND Department LIKE @Department';
        END

    SET @Params = N'@Name NVARCHAR(100), @Email NVARCHAR(100), @Department NVARCHAR(100)';
    EXEC sp_executesql @SQL, @Params,
         @Name = @Name,
         @Email = @Email,
         @Department = @Department;
END
GO


EXEC SearchEmployees @Name = 'ABC 10', @Email = '10@'
GO



-- MD2

-- Uzrakstīt SQL funkciju, kura pārveido jebkuru vārdu tā, lai pirmais burts būtu lielais,
-- nākamais mazais, tad atkal lielais, utt.
-- Piem: grāmata -> GrĀmAtA
-- Piem: Darbs -> DaRbS
-- Ideja: izmantot WHILE ciklu un @n INT mainīgo, kas iet no 1 līdz vārda garumam.

CREATE FUNCTION AlternateLetterCasing(@InputStr VARCHAR(MAX))
    RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @ResultStr VARCHAR(MAX) = '';
    DECLARE @i INT = 1;
    DECLARE @CurrentChar CHAR(1);

    WHILE @i <= LEN(@InputStr)
        BEGIN
            -- Extract a single character from the string
            SET @CurrentChar = SUBSTRING(@InputStr, @i, 1);

            -- Alternate casing: Uppercase for odd positions, Lowercase for even
            IF @i % 2 = 1
                SET @ResultStr = @ResultStr + UPPER(@CurrentChar);
            ELSE
                SET @ResultStr = @ResultStr + LOWER(@CurrentChar);

            SET @i = @i + 1;
        END

    RETURN @ResultStr;
END

-- MD3

-- Uzrakstīt SQL funkciju, kura no CSP.dbo.goaldatums_2023gads tabulas saņem parametru VRN (piemēram 0x51C3E145C2A83472E19C3612609018094C788F44A96860E5817C5E8076680FCA)
-- un atgriež, cik KM ir reģistrētais nobraukums (lielākais - mazākais Odometra rādījums)


CREATE FUNCTION CalculateTotalDistance(@VRN VARCHAR(MAX))
    RETURNS INT
AS
BEGIN
    declare @ret INT;
    select @ret = max(PED_ODOMETRA_RADIJUMS) - min(IEPRIEKS_ODOMETRA_RADIJUMS)
    from goaldatums_2023gads
    where VRN = @VRN
    group by VRN;
    return @ret
END
GO

select dbo.CalculateTotalDistance(VRN),
       *
from goaldatums_2023gads
where VRN = '0x51C3E145C2A83472E19C3612609018094C788F44A96860E5817C5E8076680FCA'

-- MD4

-- Uzrakstīt procedūru, kura kā ieejas parametru saņem UUK vērtību no tea.VDVV_2017 tabulas un uz ekrāna
-- ar PRINT palīdzību izdrukā informāciju par objektu, apvienojot to ar web.nace_2 informāciju:
-- Piemērs:
-- Zobārstniecības kabinets, kas atrodas Talsu iela 31, Ventspils, LV-3602, nodarbojas ar "Zobārstu prakse"

USE CSP;
GO;
create procedure MD4 @UUK VARCHAR(max)
AS
declare @nosaukums varchar(max);
declare @adrese varchar(max);
declare @nace varchar(max);
select @nosaukums = v.Nosaukums,
       @adrese = v.Adrese,
       @nace = n.nosaukums
from SQL_Study_2023.tea.VDVV_2017 v
         left join SQL_Study_2023.web.nace_2 n on REPLACE(n.kods, '.', '') = v.NACE
where v.UUK = @UUK;
    PRINT (@nosaukums + ', kas atrodas ' + @adrese + ' nodarbojas ar "' + @nace + '"');
GO;

EXECUTE dbo.MD4 @UUK = '99195204';


-- MD4.2
-- Pārveidot šo uzdevumu kā Batch Skriptu, kurš ar CURSOR palīdzību izvada šo informāciju visiem tabulas ierakstiem
-- kas atrodas Rīgā. Kā noteikt Rīgu?

use SQL_Study_2023;
GO;
select Adrese
from tea.VDVV_2017
WHERE Adrese like '%LV-10%'


select UUK,
       Nosaukums,
       geom.ToString()
from tea.VDVV_2017

USE SQL_Study_2023;
DECLARE @UUK       VARCHAR(max)
declare @nosaukums varchar(max);
declare @adrese varchar(max);
declare @nace varchar(max);

declare cur CURSOR FOR
    select top 100 v.Nosaukums,
                   v.Adrese,
                   n.nosaukums
    from SQL_Study_2023.tea.VDVV_2017 v
             left join SQL_Study_2023.web.nace_2 n on REPLACE(n.kods, '.', '') = v.NACE
OPEN cur;
fetch next from cur into @nosaukums, @adrese, @nace;
while @@fetch_status = 0
    begin
        PRINT (@nosaukums + ', kas atrodas ' + @adrese + ' nodarbojas ar "' + @nace + '"');
        fetch next from cur into @nosaukums, @adrese, @nace;
    end
CLOSE cur;
DEALLOCATE cur;
GO;



select *
from goaldatums_2023gads
where VRN = '0xE72E0B36CAF6AB4A0003DCEF3C9F110339334DDFE5F1CD208968F2E190FACD27'
ORDER BY PERIODS;


-- Izpētīt sekojošu skriptu, kurš katrai automašīnai, kurai trūkst dati, uz ekrāna izvada trūkstošos periodus
GO
DECLARE
    ATD_CURSOR CURSOR FOR
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
    WHERE DATEDIFF(MONTH, PERIODS_IEPR_DATE, PERIODS_DATE) > 3
      AND VRN = '0xE72E0B36CAF6AB4A0003DCEF3C9F110339334DDFE5F1CD208968F2E190FACD27'
    ORDER BY STARPIBA DESC

DECLARE @VRN VARCHAR(200);
DECLARE @PERIODS_DATE DATE;
DECLARE @PERIODS_IEPR_DATE DATE;
DECLARE @STARPIBA INT;

OPEN ATD_CURSOR
FETCH NEXT FROM ATD_CURSOR INTO @VRN, @PERIODS_DATE, @PERIODS_IEPR_DATE, @STARPIBA
WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT ('VRN: ' + @VRN + ' ' + CAST(@PERIODS_DATE as VARCHAR) + ' ' + CAST(@PERIODS_IEPR_DATE as VARCHAR))
        SET @PERIODS_IEPR_DATE = DATEADD(MONTH, 1, @PERIODS_IEPR_DATE);
        WHILE @PERIODS_IEPR_DATE < @PERIODS_DATE
            BEGIN
                PRINT (@PERIODS_IEPR_DATE)
                INSERT INTO goaldatums_2023gads (VRN, PERIODS) VALUES (@VRN, FORMAT(@PERIODS_IEPR_DATE, 'yyyyMM'));
                SET @PERIODS_IEPR_DATE = DATEADD(MONTH, 1, @PERIODS_IEPR_DATE);
                -- Pirmais uzdevums - pārveidot skriptu tā, lai izvadās tikai TRŪKSTOŠIE PERIODI
                -- Otrais: papildināt PRINT ar INSERT vaicājumu, lai trūkstošo periodu info pievienotos datu  bāzē!
            END
        FETCH NEXT FROM ATD_CURSOR INTO @VRN, @PERIODS_DATE, @PERIODS_IEPR_DATE, @STARPIBA
    END
CLOSE ATD_CURSOR;
DEALLOCATE ATD_CURSOR;
GO;

--- GIT VERSIJU KONTROLE

---- SPATIAL

select ID,
       geom.ToString(),
       geom.STAsText()
from Grid_LV_1k

select ID,
       L1_name,
       geom.STAsText()
from VZD_teritorialas_vienibas_2017
where geom.STGeometryType() <> 'MultiPolygon'


select Nosaukums,
       Adrese,
       X,
       Y,
       geom.STAsText()
from tea.VDVV_2017


select v.*
from tea.VDVV_2017 v
         inner join VZD_teritorialas_vienibas_2017 t
                    on t.geom.STContains(v.geom) = 1
where t.L1_name = 'Līgatne'
