-- MD1
GO
DECLARE
    ATD_CURSOR CURSOR FOR
    WITH CTE1 AS (select VRN,
                         PERIODS,
                         PED_ODOMETRA_RADIJUMS,
                         LAG(PERIODS, 1) OVER (partition by VRN order by PERIODS) PERIODS_IEPR
                  from goaldatums_2023gads)
       , CTE2 AS (SELECT VRN,
                         PED_ODOMETRA_RADIJUMS,
                         CAST(PERIODS + '01' AS DATE)      as PERIODS_DATE,
                         CAST(PERIODS_IEPR + '01' AS DATE) as PERIODS_IEPR_DATE
                  FROM CTE1)

    select VRN,
           PED_ODOMETRA_RADIJUMS,
           PERIODS_DATE,
           PERIODS_IEPR_DATE,
           DATEDIFF(MONTH, PERIODS_IEPR_DATE, PERIODS_DATE) AS STARPIBA
    FROM CTE2
    WHERE DATEDIFF(MONTH, PERIODS_IEPR_DATE, PERIODS_DATE) > 3
      AND VRN = '0x7430E3A5AD6AEAE61203A395A2E1BA0371F67AAFA7B64E72A9449E0D7D40B890'
    ORDER BY STARPIBA DESC

DECLARE @VRN VARCHAR(200);
DECLARE @PERIODS_DATE DATE;
DECLARE @PERIODS_IEPR_DATE DATE;
DECLARE @PED_ODOMETRA_RADIJUMS INT;
DECLARE @STARPIBA INT;

OPEN ATD_CURSOR
FETCH NEXT FROM ATD_CURSOR INTO @VRN, @PED_ODOMETRA_RADIJUMS, @PERIODS_DATE, @PERIODS_IEPR_DATE, @STARPIBA
WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT ('VRN: ' + @VRN + ' ' + CAST(@PERIODS_DATE as VARCHAR) + ' ' + CAST(@PERIODS_IEPR_DATE as VARCHAR))
        SET @PERIODS_IEPR_DATE = DATEADD(MONTH, 1, @PERIODS_IEPR_DATE);
        WHILE @PERIODS_IEPR_DATE < @PERIODS_DATE
            BEGIN
                PRINT (@PERIODS_IEPR_DATE)
                PRINT (@PED_ODOMETRA_RADIJUMS);
--                 INSERT INTO goaldatums_2023gads (VRN, PERIODS) VALUES (@VRN, FORMAT(@PERIODS_IEPR_DATE, 'yyyyMM'));
                SET @PERIODS_IEPR_DATE = DATEADD(MONTH, 1, @PERIODS_IEPR_DATE);
                -- Pirmais uzdevums - pārveidot skriptu tā, lai izvadās tikai TRŪKSTOŠIE PERIODI
                -- Otrais: papildināt PRINT ar INSERT vaicājumu, lai trūkstošo periodu info pievienotos datu  bāzē!
            END
        FETCH NEXT FROM ATD_CURSOR INTO @VRN, @PED_ODOMETRA_RADIJUMS, @PERIODS_DATE, @PERIODS_IEPR_DATE, @STARPIBA
    END
CLOSE ATD_CURSOR;
DEALLOCATE ATD_CURSOR;
GO;


-- MD2
-- goaldatums_2023gads - katrai automašīnai (VRN) (varam sākumā vienai, tad ar CURSOR katrai), uzrakstīt skriptu,
-- kurš iegūst visus pieejamos dažādos TA datumus (TA_DATUMS):
-- ja tāds ir 1, tad mūsu gadījumā izlaižam
-- ja tādi ir 2, tad aprēķinam periodu mēnešos starp tiem
-- ja tādi ir 3 vai vairāk, tad atrast garāko periodu (piem, starp 1 un 2 vai 2 un 3)
-- tad kad periods atrasts, tad noskaidrot nobraukuma (PED_ODOMETRA_RADIJUMS) starpību, starp šiem diviem datumiem.
-- var arī meklēt nevis garāko periodu starp TA, bet to, kas tuvāks 12 mēnešiem, tomēr mums ir tikai viena gada dati,
-- tāpēc tas šķiet nebūs iespējams - jebkurā gadījumā, šis nosacījums jau būtu viegli pamaināms.

-- šis ir paliels uzdevums, tāpēc var risināt pakāpeniski, izmēģināt dažādas pieejas (īpaši sākotnējo SQL ar kuru atlasām datus)
-- var arī pamainīt uzdevuma nosacījumus, to aprakstot
-- arī daļējus risinājumus lūdzu iesūtīt, lai varu nokomentēt!

declare
    ta_curs CURSOR FOR
    select VRN, TA_DATUMS, PED_ODOMETRA_RADIJUMS
    from goaldatums_2023gads
    where VRN in ( '0xFE6A67555D3314E941E99EE8AB574C624DB8B806886355BB55D985D83B183F5F', '0x7430E3A5AD6AEAE61203A395A2E1BA0371F67AAFA7B64E72A9449E0D7D40B890')
    GROUP BY VRN, TA_DATUMS, PED_ODOMETRA_RADIJUMS
    ORDER BY VRN, TA_DATUMS

-- deklarejam mainigos
declare @vrn varchar(max), @vrn_prev varchar(max) = null;
declare @ta_datums datetime;
declare @ped_odometra_radijums int;
declare @start datetime = null, @stop datetime = null;
declare @current_diff int = 0, @max_diff int = 0;
declare @max_start datetime, @max_stop datetime;
declare @odo_start int, @odo_max int;

open ta_curs;
fetch next from ta_curs into @vrn, @ta_datums, @ped_odometra_radijums;

while @@fetch_status = 0 -- ārējais cikls pārlasa visus atrastos VRN
    begin
        print('VRN processing: ' + @vrn);
        set @start = @ta_datums; -- intervāla sākums
        set @odo_start = @ped_odometra_radijums;
        set @odo_max = 0;
        set @max_diff = 0; -- pirms katra jauna numura reset atrastajam periodam
        set @vrn_prev = @vrn;
        while @vrn = @vrn_prev and @@fetch_status = 0 -- kamēr esam viena VRN ietvaros (un nav beigušies dati), dažādi TA datumi
            begin
                set @vrn_prev = @vrn;
                set @stop = @ta_datums; -- intervāla beigas
                set @current_diff = datediff(day, @start, @stop);
                if @current_diff > @max_diff -- ja esam atraduši garāku TA periodu nekā līdz šim
                    begin
                        set @max_diff = @current_diff;
                        set @max_start = @start;
                        set @max_stop = @stop;
                        set @odo_max = @ped_odometra_radijums - @odo_start;
                    end
                set @start = @stop; -- pārceļam sākumu uz beigām un ejam tālāk
                set @odo_start = @ped_odometra_radijums;
                fetch next from ta_curs into @vrn, @ta_datums, @ped_odometra_radijums
            end
        print 'max_start: ' + cast(@max_start as varchar);
        print 'max_stop: ' + cast(@max_stop as varchar);
        print 'max_diff: ' + cast(@max_diff as varchar);
        print 'odo: ' + cast(@odo_max as varchar);
    end

close ta_curs;
deallocate ta_curs;
;
GO;
---- SPATIAL

USE SQL_Study_2023;
GO;
select ID,
       geom.ToString(),
       geom.STAsText(),
       geom.STAsBinary()
from Grid_LV_1k


select L1_name, geom, geom.STAsText()
from
VZD_teritorialas_vienibas_2017;

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


DECLARE @Sq geometry  =
geometry::STGeomFromText('LINESTRING (10 10, 10 100, 100 100, 100 10, 10 10)', 0);
SELECT @Sq

DECLARE @circle geometry
= geometry::Parse('CIRCULARSTRING(3 2, 2 3, 1 2, 2 1, 3 2)');
select @circle


DECLARE @g geometry;
SET @g = geometry::Parse('CIRCULARSTRING(2 1, 1 2, 0 1, 1 0, 2 1)');
SELECT @g, 'Circumference = ' + CAST(@g.STLength() AS NVARCHAR(10));


DECLARE @Tri geometry
=  geometry::STGeomFromText('POLYGON((100 100,200 300,300 100, 100 100))', 0);
select @Tri


DECLARE @Sqfilled geometry
= geometry::STGeomFromText('POLYGON((10 10, 10 100, 100 100, 100 10, 10 10))', 0);
SELECT @Sqfilled


DECLARE @Sq geometry
= geometry::STGeomFromText('POLYGON((15 15, 15 250, 250 250, 250 15, 15 15))', 0),
@Tri geometry
= geometry::STGeomFromText('POLYGON((100 100,200 300,300 100, 100 100))', 0);

SELECT @Sq
UNION ALL
SELECT @Tri


DECLARE @Sq geometry
= geometry::STGeomFromText('POLYGON((15 15, 15 250, 250 250, 250 15, 15 15))', 0),
@Tri geometry
= geometry::STGeomFromText('POLYGON((100 100,200 300,300 100, 100 100))', 0);

SELECT @Sq.STUnion(@Tri)

DECLARE @Sq geometry
= geometry::STGeomFromText('POLYGON((15 15, 15 250, 250 250, 250 15, 15 15))', 0),
@Tri geometry
= geometry::STGeomFromText('POLYGON((100 100,200 300,300 100, 100 100))', 0);

SELECT @Sq.STIntersection(@Tri)


DECLARE @Sq geometry
= geometry::STGeomFromText('POLYGON((15 15, 15 250, 250 250, 250 15, 15 15))', 0),
@Tri geometry
= geometry::STGeomFromText('POLYGON((100 100,200 300,300 100, 100 100))', 0);

SELECT @Sq.STSymDifference(@Tri)

---

-- atrast parāda pieagumu starp pirmo un pēdējo gadu

select
    Pasvaldibas_ID,
    Pasvaldibas_nosaukums,
    Gads,
    EUR,
    FIRST_VALUE(EUR) over (PARTITION BY Pasvaldibas_ID ORDER BY Gads) as First,
    LAST_VALUE(EUR) over (PARTITION BY Pasvaldibas_ID ORDER BY Gads ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as Last
from vk.dati
order by Pasvaldibas_ID, Gads
