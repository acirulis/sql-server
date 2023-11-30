-- izveidojam tabulu
use CSP;
Create Table Employees_Andis
(
    Id         int primary key identity,
    [Name]     nvarchar(50),
    Email      nvarchar(50),
    Department nvarchar(50)
)

-- Ievietojam datus
Go
SET NOCOUNT ON
Declare @counter int = 1

While(@counter <= 500000)
    Begin
        Declare @Name nvarchar(50) = 'Andis ' + RTRIM(@counter)
        Declare @Email nvarchar(50) = 'abc' + RTRIM(@counter) + '@csp.gov.lv'
        Declare @Dept nvarchar(10) = 'Dept ' + RTRIM(@counter)

        Insert into Employees_Andis values (@Name, @Email, @Dept)

        Set @counter = @counter + 1

        If (@Counter % 50000 = 0)
            Print RTRIM(@Counter) + ' rows inserted'
    End


-- Pārbaudām Execution Plan bez indeksiem

-- Atrodam random rindiņu - pārskatām datus izlases kārtībā

select *
from Employees_Andis tablesample (1 percent)

-- Nokopejam e-pastu un izpildam ar Execution Plan

select *
from Employees_Andis
where email = 'abc5344@csp.gov.lv'

-- Uzliekam Indeksu, atkal izpildam to pašu vaicajumu

select *
from Employees_Andis
where email = 'abc5344@csp.gov.lv'


-----------------------------

-- Piemērs kā pielietot STRING_AGG preces_IM_EX tabulai.

-- variants, kas šķietami varētu strādāt, bet nestrādās
select valsts,
       sum(vertiba),
       string_agg(men, ',')
from preces_IM_EX
where valsts in ('AE', 'AT', 'DK', 'EE', 'IT', 'TR')
  and P = 'E'
group by valsts
order by valsts

-- saprotam kāpēc nestrādās, atlasot izejas datus:
select valsts,
       men,
       vertiba
from preces_IM_EX
where valsts in ('AE')
  and P = 'E'


------ AR CTE
WITH sagrupets_pa_menesiem as (select valsts,
                                      men,
                                      sum(vertiba) as eksporta_summa
                               from preces_IM_EX
                               where valsts in ('AE', 'AT', 'DK', 'EE', 'IT', 'TR')
                                 and P = 'E'
                               group by valsts, men
    --having sum(vertiba) > 100000
)
select valsts,
       STRING_AGG(men, '; '),
       SUM(eksporta_summa) as kopejais_eksports
from sagrupets_pa_menesiem t
group by valsts
;
----------


------ AR CTE - sakārtoti dati STRING_AGG funkcijā
WITH sagrupets_pa_menesiem as (select valsts,
                                      men,
                                      sum(vertiba) as eksporta_summa
                               from preces_IM_EX
                               where valsts in ('AE', 'AT', 'DK', 'EE', 'IT', 'TR')
                                 and P = 'E'
                               group by valsts, men
    --having sum(vertiba) > 100000
)
select valsts,
       STRING_AGG(men, '; ') WITHIN GROUP (ORDER BY men ASC),
       SUM(eksporta_summa) as kopejais_eksports
from sagrupets_pa_menesiem
group by valsts

----------


--
----------------------------------
--- https://data.gov.lv/dati/lv/dataset/gada-parskatu-finansu-dati
--- https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fdati.ur.gov.lv%2Ffinancial_data%2FFinansu_datu_lauku_skaidrojumi.xlsx&wdOrigin=BROWSELINK

select fs.legal_entity_registration_number,
       fs.year,
       fs.employees,
       fis.net_turnover,
       fis.net_income,
       fbs.total_assets,
       fbs.accounts_receivable
from ur.financial_statements fs
         left join ur.income_statements fis on fs.id = fis.statement_id
         left join ur.balance_sheets fbs on fs.id = fbs.statement_id
         left join ur.cash_flow_statements fcs on fs.id = fcs.statement_id
where legal_entity_registration_number = '45403002273'
order by fs.year asc;

-- Atlasīt uzņēmumus, kuru net_income ir lielāks par 0. Vai šādu uzņēmumu skaits pa gadiem pieaug vai samazinās?

-- Vai vidējais uzņēmumu apgrozījums  pa gaidiem pieaug vai samazinās?

-- Kāda tipa uzņēmumi visvairāk?

-- Kāda tipa uzņēmumiem vislielākais apgrozījums peļņa?

-- Kurā mēnesī reģistrēti visvairāk uzņēmumi?

-- Kurā mēnesī reģistrētajiem uzņēmumiem vislielākā peļņa?
-- straujākais pieaugums


-- Salīdzināt uzņēmumu 2021. un 2020. gada apgrozījumu (net_turnover)

-- CORRELATED SQ
with dati as (select fs.legal_entity_registration_number as registration_number,
                     fs.year,
                     fis.net_turnover
              from ur.income_statements fis
                       left join ur.financial_statements_unique fs on fis.statement_id = fs.id
              where fis.net_turnover > 1000000
                and fs.year in (2021, 2020)),

     kopa as (select d21.registration_number,
                     d21.net_turnover                                                         net_turnoever_2021,
                     (select net_turnover as net_turnover_2020
                      from dati
                      where year = 2020 and registration_number = d21.registration_number) as net_turnover_2020
              from dati d21
              where d21.year = 2021)

select *
from kopa;


-- JOINS
GO
with year_2020 as (select fs.legal_entity_registration_number as registration_number,
                          fs.year,
                          fis.net_turnover
                   from ur.income_statements fis
                            left join ur.financial_statements_unique fs on fis.statement_id = fs.id
                   where fis.net_turnover > 1000000
                     and fs.year = 2020),
     year_2021 as (select fs.legal_entity_registration_number as registration_number,
                          fs.year,
                          fis.net_turnover
                   from ur.income_statements fis
                            left join ur.financial_statements_unique fs on fis.statement_id = fs.id
                   where fis.net_turnover > 1000000
                     and fs.year = 2021)

select year_2020.registration_number,
       year_2020.net_turnover                          as t_2020,
       year_2021.net_turnover                          as t_2021,
       year_2021.net_turnover - year_2020.net_turnover as bal
from year_2020
         inner join year_2021 on year_2020.registration_number = year_2021.registration_number
order by bal desc;


--- AR SELF JOIN
select t20.*,
       t21.net_turnover as nt21
from turnover_combined t20
         inner join turnover_combined t21 on t20.registration_number = t21.registration_number and t21.year = 2021
where t20.year = 2020


-- Kāpēc ir vairāk kā viens gada pārskats?
-- MĀJAS DARBS
-- Zemāk redzamais vaicājums parāda, ka financial_statements tabulā vienam uzņēmumam var būt vairāk kā viens gada  pārskats.
-- Uzdevums izveidot vaicājumu, kurš atlasa tikai vienu gada pārskatu katram uzņēmumam
-- katrā gadā. Ja ir vairāki, izvēlēties jaunāko (vēlāk iesniegto)!

select legal_entity_registration_number,
       year,
       count(*)

from ur.financial_statements
group by legal_entity_registration_number, year
having count(*) > 1

