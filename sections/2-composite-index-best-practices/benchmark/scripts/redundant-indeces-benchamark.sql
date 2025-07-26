USE world;
-- display the indexes on the table userinfo
show indexes from userinfo ;

-- drop the comosite index
drop index name_state_idx on userinfo;

-- Q1  
SELECT COUNT(*) FROM userinfo WHERE state_id = 5;
-- Q2 
SELECT state_id , city , address FROM userinfo WHERE state_id = 100;

--  we want to bench mark the differences between having only one index on state_id  , having only one composite index on (state_id , city , address) , having both indexes (redundant)
-- so we should try Q1 with the first index and anazlye it and then drop it and then create composite index and try it and then , create the first index again to have both for bench mark

CREATE INDEX idx_state_id ON userinfo(state_id);

-- Run EXPLAIN for both queries
EXPLAIN SELECT COUNT(*) FROM userinfo WHERE state_id = 5;
EXPLAIN SELECT state_id, city, address FROM userinfo WHERE state_id = 100;

-- Optionally, measure timing
SET PROFILING = 1;
SELECT COUNT(*) FROM userinfo WHERE state_id = 5;
SHOW PROFILES;


-- -------------------------------------------------
DROP INDEX idx_state_id ON userinfo;
DROP INDEX idx_state_city_address ON userinfo;

CREATE INDEX idx_state_city_address ON userinfo(state_id, city, address);

-- Run EXPLAIN again
EXPLAIN SELECT COUNT(*) FROM userinfo WHERE state_id = 5;
EXPLAIN SELECT state_id, city, address FROM userinfo WHERE state_id = 100;
-- -------------------------------------------------
CREATE INDEX idx_state_id ON userinfo(state_id);  -- add single index again

-- Run EXPLAIN again
EXPLAIN SELECT COUNT(*) FROM userinfo WHERE state_id = 5;
EXPLAIN SELECT state_id, city, address FROM userinfo WHERE state_id = 100;

----------------------------------------------------
-- query to check the redundant indexes 
SELECT * FROM SYS.SCHEMA_REDUNDANT_INDEXES

