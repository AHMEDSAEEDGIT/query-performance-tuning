USE WORLD;

-- e1 example on 1M record and name and state have no index !
EXPLAIN ANALYZE SELECT COUNT(*) FROM userinfo WHERE name = 'John100' and state_id =100;
-- -> Aggregate: count(0)  (cost=104831 rows=1) (actual time=522..522 rows=1 loops=1)
--     -> Filter: ((userinfo.state_id = 100) and (userinfo.`name` = 'John100'))  (cost=103840 rows=9909) (actual time=3.29..522 rows=100 loops=1)
--         -> Table scan on userinfo  (cost=103840 rows=990880) (actual time=0.0665..470 rows=1e+6 loops=1)


-- e2 example on 1M record and name and state have two seprate indices !
ALTER TABLE userinfo ADD INDEX name_idx(name);
ALTER TABLE userinfo ADD INDEX state_idx (state_id);

-- Make sure after adding index on a table to analyze to update the table statistics
ANALYZE TABLE userinfo;

-- execute the query again 
EXPLAIN ANALYZE SELECT COUNT(*) FROM userinfo WHERE name = 'John100' and state_id =100;
-- -> Aggregate: count(0)  (cost=5.37 rows=1) (actual time=0.558..0.558 rows=1 loops=1)
--     -> Filter: ((userinfo.state_id = 100) and (userinfo.`name` = 'John100'))  (cost=5.27 rows=1) (actual time=0.445..0.552 rows=100 loops=1)
--         -> Intersect rows sorted by row ID  (cost=5.27 rows=1) (actual time=0.442..0.532 rows=100 loops=1)                                                 -- note here the esitmated is 1 and the actual is 100 !
--             -> Index range scan on userinfo using name_idx over (name = 'John100')  (cost=4.09 rows=100) (actual time=0.0388..0.088 rows=100 loops=1)
--             -> Index range scan on userinfo using state_idx over (state_id = 100)  (cost=1.07 rows=100) (actual time=0.401..0.433 rows=100 loops=1)



-- e3 example on 1M record and name and state have composite index  !
-- Drop the previous indices
DROP INDEX name_idx ON userinfo;
DROP INDEX state_idx ON userinfo;

-- Craete composite index
ALTER TABLE userinfo ADD INDEX name_state_idx (name , state_id);

-- execute the query again 
EXPLAIN ANALYZE SELECT COUNT(*) FROM userinfo WHERE name = 'John100' and state_id =100;
-- -> Aggregate: count(0)  (cost=24.1 rows=1) (actual time=0.0917..0.0918 rows=1 loops=1)
--     -> Covering index lookup on userinfo using name_state_idx (name='John100', state_id=100)  (cost=14.1 rows=100) (actual time=0.0448..0.0853 rows=100 loops=1)

