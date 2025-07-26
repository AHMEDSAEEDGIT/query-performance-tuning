# 📊 Index Performance Comparison in MySQL
In this session, we'll verify how indexing affects query performance using MySQL's EXPLAIN ANALYZE. We'll test three different scenarios:

- No indexes
- Two individual indexes
- One composite index

## 🧪 Goal
Compare the response time and query plan when querying a table with:

- No index
- Two separate indexes on name and state_id
- A composite index on (name, state_id)

---

## 📋 Table Description
The table userinfo stores contact information, including:


```sql
CREATE TABLE userinfo (
    id int unsigned NOT NULL AUTO_INCREMENT,
    name varchar(64) NOT NULL DEFAULT '',
    email varchar(64) NOT NULL DEFAULT '',
    password varchar(64) NOT NULL DEFAULT '',
    dob date DEFAULT NULL,
    address varchar(255) NOT NULL DEFAULT '',
    city varchar(64) NOT NULL DEFAULT '',
    state_id smallint unsigned NOT NULL DEFAULT '0',
    zip varchar(8) NOT NULL DEFAULT '',
    country_id smallint unsigned NOT NULL DEFAULT '0',
    account_type varchar(32) NOT NULL DEFAULT '',
    closest_airport varchar(3) NOT NULL DEFAULT '',
    PRIMARY KEY (id),
    UNIQUE KEY email (email)
);
```

 We'll insert 1 million rows using a procedure . The procedure populates the table with incrementing values of name and state_id, to ensure variability.


## ⚙ Data Generation
To populate the table, we use the following procedure (run in MySQL):



```sql 
DELIMITER //
CREATE PROCEDURE insert_userinfo_duplicate_data (IN num_records INT)
BEGIN
    DECLARE x INT DEFAULT 0;
    DECLARE state_id INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000; -- Adjust batch size as needed
    DECLARE batch_count INT DEFAULT num_records / batch_size;
    DECLARE current_batch INT DEFAULT 0;
    
    -- Base parameters (similar to Python script)
    SET @name = 'John';
    SET @email_base = 'John.smith@email.com';
    SET @password = '1234';
    SET @dob = '1986-02-14';
    SET @address = '1795 Santiago de Compostela Way';
    SET @city = 'Austin';
    SET @zip = '18743';
    SET @country_id = 1;
    SET @account_type = 'customer account';
    SET @airport = 'aut';
    
    -- Start timing (for benchmarking)
    SET @start_time = NOW(6);
    
    WHILE current_batch < batch_count DO
        START TRANSACTION;
        
        SET x = current_batch * batch_size;
        WHILE x < (current_batch + 1) * batch_size AND x < num_records DO
            -- Increment state_id every 100 records 
            IF x MOD 100 = 0 THEN
                SET state_id = state_id + 1;
            END IF;
            
            -- Insert record with generated values
            INSERT INTO userinfo (
                name, email, password, dob, address, city, 
                state_id, zip, country_id, account_type, closest_airport
            ) VALUES (
                CONCAT(@name, state_id), 
                CONCAT(@email_base, x), 
                @password, 
                @dob, 
                @address, 
                @city, 
                state_id, 
                @zip, 
                @country_id, 
                @account_type, 
                @airport
            );
            
            SET x = x + 1;
        END WHILE;
        
        COMMIT;
        
        -- Progress reporting (every 10 batches)
        IF current_batch MOD 10 = 0 THEN
            SELECT CONCAT('Inserted ', x, ' of ', num_records, ' records') AS progress;
        END IF;
        
        SET current_batch = current_batch + 1;
    END WHILE;
    
    -- Calculate and display total time
    SET @total_time = TIMESTAMPDIFF(MICROSECOND, @start_time, NOW(6)) / 1000000;
    SELECT CONCAT('Total time: ', @total_time, ' seconds') AS result;
    
    -- Final count verification
    SELECT COUNT(*) AS total_records_inserted FROM userinfo WHERE email LIKE CONCAT(@email_base, '%');
END //
DELIMITER ;
```

---

## 🔍 Benchmark Strategy
We’ll execute the same query:

```sql
SELECT COUNT(*) FROM userinfo WHERE name = 'John100' AND state_id = 100;
```

We measure:


- Query response time
- Query execution plan via `EXPLAIN ANALYZE`

## 📉 Scenario 1: No Index
**Query**

```sql
EXPLAIN ANALYZE SELECT COUNT(*) FROM userinfo WHERE name = 'John100' AND state_id = 100;
```

```text
-> Aggregate: count(0)  (cost=104831 rows=1) (actual time=522..522 rows=1 loops=1)
    -> Filter: ((userinfo.state_id = 100) and (userinfo.`name` = 'John100'))   (cost=103840 rows=9909) (actual time=3.29..522 rows=100 loops=1)
        -> Table scan on userinfo   (cost=103840 rows=990880) (actual time=0.0665..470 rows=1e+6 loops=1)
```
> [!CAUTION]
> Full table scan — extremely slow on large datasets.

&nbsp;

## 📈 Scenario 2: Two Individual Indexes
#### Step 1: Add Indexes
```sql
ALTER TABLE userinfo ADD INDEX name_idx(name);
ALTER TABLE userinfo ADD INDEX state_idx(state_id);
```
```sql
ANALYZE TABLE userinfo; -- to update statistics
```
#### Step 2: Run the Query Again

```sql
EXPLAIN ANALYZE SELECT COUNT(*) FROM userinfo WHERE name = 'John100' AND state_id = 100;
```
**Result:**
```text
-> Aggregate: count(0)  (cost=5.37 rows=1) (actual time=0.558..0.558 rows=1 loops=1)
    -> Filter: ((userinfo.state_id = 100) and (userinfo.`name` = 'John100')) (cost=5.27 rows=1) (actual time=0.445..0.552 rows=100 loops=1)
        -> Intersect rows sorted by row ID  (cost=5.27 rows=1) (actual time=0.442..0.532 rows=100 loops=1)
            -> Index range scan on userinfo using name_idx over (name = 'John100') (cost=4.09 rows=100) (actual time=0.0388..0.088 rows=100 loops=1)
            -> Index range scan on userinfo using state_idx over (state_id = 100) (cost=1.07 rows=100) (actual time=0.401..0.433 rows=100 loops=1)\
```

> [!WARNING]
>  MySQL intersects the two indexes, which is faster than a full scan, but not perfect.

> [!NOTE]
> Estimated rows = 1, actual rows = 100 (underestimation can lead to suboptimal plans)

&nbsp;

## 🚀 Scenario 3: Composite Index on (name, state_id)
#### Step 1: Drop Previous Indexes
```sql
DROP INDEX name_idx ON userinfo;
DROP INDEX state_idx ON userinfo;
```

#### Step 2: Add Composite Index

```sql
ALTER TABLE userinfo ADD INDEX name_state_idx (name, state_id);
```

#### Step 3: Run the Query Again
```sql
EXPLAIN ANALYZE SELECT COUNT(*) FROM userinfo WHERE name = 'John100' AND state_id = 100;
```

**Result**

-> Aggregate: count(0)  (cost=24.1 rows=1) (actual time=0.0917..0.0918 rows=1 loops=1)
    -> Covering index lookup on userinfo using name_state_idx (name='John100', state_id=100) (cost=14.1 rows=100) (actual time=0.0448..0.0853 rows=100 loops=1)
> ✅ Fastest result — MySQL performs a covering index lookup with accurate row estimates.


