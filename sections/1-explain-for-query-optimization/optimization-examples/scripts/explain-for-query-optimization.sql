
USE world;
EXPLAIN  SELECT * FROM CITY WHERE NAME = 'London';

SHOW TABLES;
SHOW COLUMNS IN city;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- #example 1 (filter single table without index)
EXPLAIN ANALYZE  SELECT * FROM CITY WHERE NAME = 'London';
-- -> Filter: (city.`Name` = 'London')  (cost=411 rows=405) (actual time=0.352..1.92 rows=2 loops=1)
--      -> Table scan on CITY  (cost=411 rows=4046) (actual time=0.138..1.57 rows=4079 loops=1)


-- #example 2 (filter single table with non-unique-index column)
EXPLAIN ANALYZE SELECT * FROM city WHERE CountryCode = 'FRA'; -- note that  CountryCode has an index
-- -> Index lookup on city using CountryCode (CountryCode='FRA'), with index condition: (city.CountryCode = 'FRA')  (cost=14 rows=40) (actual time=0.094..0.164 rows=40 loops=1)
 

-- example 3 (filter single table with composite primary key index)
EXPLAIN ANALYZE SELECT * FROM CountryCode WHERE countrylanguage = 'CHN'; -- note here we are filtering with the first column in the composite index (CountryCode)
-- -> Index lookup on city using CountryCode (CountryCode='FRA'), with index condition: (city.CountryCode = 'FRA')  (cost=14 rows=40) (actual time=0.0586..0.113 rows=40 loops=1)
 


-- example 4 (Top Cities in the Smallest European Countries)
 EXPLAIN ANALYZE SELECT ci.ID, ci.Name, ci.District,  
        co.Name AS Country, ci.Population  
 FROM world.city ci  
 INNER JOIN (  
     SELECT Code, Name  
     FROM world.country  
     WHERE Continent = 'Europe'  
     ORDER BY SurfaceArea  
     LIMIT 10  
 ) co ON co.Code = ci.CountryCode  
 ORDER BY ci.Population DESC  
 LIMIT 5;

-- 	-> Limit: 5 row(s)  (actual time=0.366..0.367 rows=5 loops=1)
--      -> Sort: ci.Population DESC, limit input to 5 row(s) per chunk  (actual time=0.366..0.366 rows=5 loops=1)
--          -> Stream results  (cost=90.3 rows=174) (actual time=0.256..0.351 rows=15 loops=1)
--              -> Nested loop inner join  (cost=90.3 rows=174) (actual time=0.255..0.346 rows=15 loops=1)
--                  -> Table scan on co  (cost=26.9..29.3 rows=10) (actual time=0.229..0.231 rows=10 loops=1)
--                      -> Materialize  (cost=26.7..26.7 rows=10) (actual time=0.228..0.228 rows=10 loops=1)
--                          -> Limit: 10 row(s)  (cost=25.7 rows=10) (actual time=0.211..0.213 rows=10 loops=1)
--                              -> Sort: country.SurfaceArea, limit input to 10 row(s) per chunk  (cost=25.7 rows=239) (actual time=0.211..0.212 rows=10 loops=1)
--                                  -> Filter: (country.Continent = 'Europe')  (cost=25.7 rows=239) (actual time=0.0519..0.182 rows=46 loops=1)
--                                      -> Table scan on country  (cost=25.7 rows=239) (actual time=0.0467..0.155 rows=239 loops=1)
--                  -> Index lookup on ci using CountryCode (CountryCode=co.`Code`)  (cost=4.53 rows=17.4) (actual time=0.0102..0.0111 rows=1.5 loops=10)
--  
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Experiment: Overestimation Due to Expression

-- first create table called "test_estimates"
CREATE TABLE test_estimates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    val INT,
    val2 INT
);
ALTER TABLE test_estimates ADD INDEX idx_val (val);

-- next create procedure to insert in that table
DELIMITER $$

CREATE PROCEDURE insert_test_data()
BEGIN
	DECLARE I INT DEFAULT 0;
    START TRANSACTION;
    WHILE I < 100000 DO
		INSERT INTO test_estimates (val, val2) VALUES (i, i);
		SET i = i + 1;
	END WHILE;
    COMMIT;
END$$

DELIMITER ;



-- Then call the procedure to insert 
CALL insert_test_data();

-- Then analyze the Table (to update optimizer stats)
ANALYZE TABLE test_estimates;

-- Then run the Query with Expression in WHERE Clause
EXPLAIN ANALYZE
SELECT * FROM test_estimates WHERE 2 * val < 3;
-- 	EXPLAIN
-- 	-> Filter: ((2 * test_estimates.val) < 3)  (cost=10082 rows=100256) (actual time=1.46..32 rows=2 loops=1)
--      -> Table scan on test_estimates  (cost=10082 rows=100256) (actual time=1.46..25.5 rows=100000 loops=1)



-- Then add Functional Index on Expression
ALTER TABLE test_estimates ADD INDEX idx_func ((2 * val));


-- Then analyze Again and Re-run the Query
ANALYZE TABLE test_estimates;

EXPLAIN ANALYZE
SELECT * FROM test_estimates WHERE 2 * val < 3;

-- 	EXPLAIN
-- 	-> Filter: ((2 * val) < 3)  (cost=1.16 rows=2) (actual time=0.0286..0.0301 rows=2 loops=1)
--      -> Index range scan on test_estimates using idx_func over (NULL < (2 * `val`) < 3)  (cost=1.16 rows=2) (actual time=0.0274..0.0288 rows=2 loops=1)
--  




