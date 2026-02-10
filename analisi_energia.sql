SELECT * FROM world_energy 
WHERE country = 'Italy' 
ORDER BY year DESC 
LIMIT 5;



SELECT 
    country, 
    solar_consumption::numeric AS consumo_solare_twh
FROM world_energy
WHERE year = 2022 
  AND iso_code IS NOT NULL
  AND solar_consumption IS NOT NULL
ORDER BY solar_consumption::numeric DESC NULLS LAST
LIMIT 10;



with trend_china as (
			select year, solar_consumption::numeric as consumption_now,
	  		lag(solar_consumption::numeric) over (order by year) as lag_year
			from world_energy
			where country = 'China'
			and solar_consumption::numeric is not null
			and solar_consumption::numeric != 0
	) 
	select *, (consumption_now - lag_year) as china_growth,
		   round(((consumption_now - lag_year)/lag_year)*100, 2) as growth_percent
		   from trend_china;


SELECT 
    country,
    renewables_share_energy::numeric AS rse,
    CASE 
        WHEN renewables_share_energy::numeric > 50 THEN 'Green'
        WHEN renewables_share_energy::numeric > 20 THEN 'In Progress' 
        ELSE 'Lagging'
    END AS category
FROM world_energy
WHERE year = 2022
  AND iso_code IS NOT NULL
  AND renewables_share_energy IS NOT NULL
ORDER BY rse DESC;


 with history as (
 select year,
 		country,
		solar_consumption::numeric,
 rank() over (partition by year order by solar_consumption::numeric desc) as classifica
 from world_energy
 where solar_consumption::numeric is not null
 and solar_consumption::numeric != 0
 and iso_code is not null
 	)
	 select *
	 from history
	 where classifica = 1
 	 order by year;


 select country, solar_consumption::numeric,
 		(solar_consumption::numeric/sum(solar_consumption::numeric) over (partition by year))*100 as global_share
 from world_energy
 where year = 2022
 and solar_consumption::numeric > 0
 and iso_code is not null
 order by 2 desc
 limit 5;


 select country, solar_consumption::numeric,
 		sum(solar_consumption::numeric) over (order by year) as cumulative_consumption
 from world_energy
 where country = 'China'
 and solar_consumption::numeric > 0;


 select year, country, solar_consumption::numeric,
 		avg(solar_consumption::numeric) over (order by year rows between 2 preceding and current row)
 from world_energy
 where country = 'China'
 and solar_consumption::numeric > 0
 and iso_code is not null
 order by 1;


 select country, solar_consumption::numeric,
 ntile(4) over (order by solar_consumption::numeric desc)
 from world_energy
 where year = 2022
 and iso_code is not null
 and solar_consumption::numeric > 0;


 with t1 as (
 select year, solar_consumption::numeric as consumption, country,
 		(solar_consumption::numeric - lag(solar_consumption::numeric) over (order by year)) as growth_twh,
		 sum(solar_consumption::numeric) over (order by year) as cumulative_total,
		 avg(solar_consumption::numeric) over (order by year rows between 2 preceding and current row) as moving_avg
 from world_energy 
 where country = 'China'
 and solar_consumption::numeric > 0
 and iso_code is not null
 	) 
	select *
	from t1
	where year >= 2018;


 with analysis_uk as(
 			 select country,
			  		iso_code,
			        year,
	                coal_consumption::numeric,
					wind_consumption::numeric,
					solar_consumption::numeric,
					wind_consumption::numeric + solar_consumption::numeric as green_energy
			 from world_energy
			 where country = 'United Kingdom'
 		     and iso_code is not null
 	         and coal_consumption::numeric > 0
 	         and wind_consumption::numeric > 0
 	         and solar_consumption::numeric > 0
			 )
 	select year, green_energy, 
	             coal_consumption::numeric, 
				 wind_consumption::numeric, 
				 solar_consumption::numeric
 	from analysis_uk
 	where green_energy > coal_consumption::numeric
 	order by year;


 WITH world_Pareto AS (
    SELECT 
        country,
        year,
        solar_consumption::numeric AS solar_consumption,
        SUM(solar_consumption::numeric) OVER (ORDER BY solar_consumption::numeric DESC) AS running_total,
        SUM(solar_consumption::numeric) OVER () AS global_total
    FROM world_energy
    WHERE solar_consumption::numeric > 0
      AND year = 2022
      AND iso_code IS NOT NULL
) 
SELECT 
    country,
    solar_consumption, 
    ROUND((running_total / global_total), 2) AS Pareto_analysis
FROM world_Pareto
ORDER BY solar_consumption DESC; 


SELECT country, 
       year,
	   solar_consumption
FROM world_energy
WHERE year >= 2010
AND country NOT IN ('World', 'Non-OECD', 'OECD', 'European Union', 'Total North America', 'Total S. & Cent. America', 'Total Europe', 'Total CIS', 'Total Middle East', 'Total Africa', 'Total Asia Pacific')
ORDER BY country, year;


 with t1 as (
 select year,
 		country,
 		coalesce(coal_consumption::numeric, 0) as carbone,
 		coalesce(oil_consumption::numeric, 0) as petrolio,
		coalesce(gas_consumption::numeric, 0) as gas,
		coalesce(solar_consumption::numeric, 0) as solare,
		coalesce(wind_consumption::numeric, 0) as eolico,
		coalesce(hydro_consumption::numeric, 0) as idroelettrico,
		coalesce(nuclear_consumption::numeric, 0) as nucleare
 from world_energy
 where year >= 2000
 and iso_code is not null
	)
	select year,
		   country,
		   carbone + petrolio + gas as combustibili_fossili,
		   solare + eolico + idroelettrico as rinnovabili,
		   nucleare
	from t1
	order by country, year;


WITH t1 AS (
    SELECT
        country,
        year,
        COALESCE(coal_consumption::numeric, 0) as carbone,
        COALESCE(oil_consumption::numeric, 0) as petrolio,
        COALESCE(gas_consumption::numeric, 0) as gas,
        COALESCE(nuclear_consumption::numeric, 0) as nucleare,
        COALESCE(hydro_consumption::numeric, 0) as idroelettrico,
        COALESCE(wind_consumption::numeric, 0) as eolico,
        COALESCE(solar_consumption::numeric, 0) as solare,
        COALESCE(biofuel_consumption::numeric, 0) as biofuel 
    FROM world_energy
    WHERE year >= 1990
      AND iso_code IS NOT NULL
)

SELECT
    country,
    year,
    (carbone + petrolio + gas + nucleare + idroelettrico + eolico + solare + biofuel) as totale_energetico
FROM
    t1
ORDER BY
    country, year;