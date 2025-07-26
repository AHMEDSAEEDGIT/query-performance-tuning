USE world;

-- Create the userinfo 
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
) ;

-- Create a procedure to generate and insert test data
DELIMITER //
CREATE PROCEDURE insert_userinfo_data (IN num_records INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000; -- Adjust batch size as needed
    DECLARE batch_count INT DEFAULT num_records / batch_size;
    DECLARE current_batch INT DEFAULT 0;
        
    -- Temporary variables for data generation
    DECLARE user_name VARCHAR(64);
    DECLARE user_email VARCHAR(64);
    DECLARE user_password VARCHAR(64);
    DECLARE user_dob DATE;
    DECLARE user_address VARCHAR(255);
    DECLARE user_city VARCHAR(64);
    DECLARE user_state_id SMALLINT UNSIGNED;
    DECLARE user_zip VARCHAR(8);
    DECLARE user_country_id SMALLINT UNSIGNED;
    DECLARE user_account_type VARCHAR(32);
    DECLARE user_airport VARCHAR(3);
    
    -- Seed for random data generation
    SET @seed = UNIX_TIMESTAMP();
    -- Common cities and airports for more realistic data
    SET @cities = 'New York,Los Angeles,Chicago,Houston,Phoenix,Philadelphia,San Antonio,San Diego,Dallas,San Jose';
    SET @airports = 'JFK,LAX,ORD,DFW,DEN,SFO,SEA,ATL,EWR,MIA';
    SET @account_types = 'standard,premium,business,enterprise,free,trial';
    
    WHILE current_batch < batch_count DO
        -- Start transaction for each batch
        START TRANSACTION;
        
        SET i = 0;
        WHILE i < batch_size DO
            -- Generate random data
            SET user_name = CONCAT('User_', @seed + i + (current_batch * batch_size));
            SET user_email = CONCAT('user', @seed + i + (current_batch * batch_size), '@example.com');
            SET user_password = SUBSTRING(MD5(RAND()), 1, 10);
            SET user_dob = DATE_ADD('1970-01-01', INTERVAL FLOOR(RAND() * 50) YEAR);
            SET user_address = CONCAT(FLOOR(RAND() * 9999) + 1, ' ', 
                                     ELT(FLOOR(RAND() * 10) + 1, 'Main', 'Oak', 'Pine', 'Maple', 'Cedar', 'Elm', 'Spruce', 'Birch', 'Willow', 'Aspen'), ' St.');
            SET user_city = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(@cities, ',', FLOOR(RAND() * 10) + 1), ',', -1));
            SET user_state_id = FLOOR(RAND() * 50) + 1;
            SET user_zip = LPAD(FLOOR(RAND() * 99999), 5, '0');
            SET user_country_id = FLOOR(RAND() * 200) + 1;
            SET user_account_type = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(@account_types, ',', FLOOR(RAND() * 6) + 1), ',', -1));
            SET user_airport = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(@airports, ',', FLOOR(RAND() * 10) + 1), ',', -1));
            
            -- Insert the record
            INSERT INTO userinfo (
                name, email, password, dob, address, city, 
                state_id, zip, country_id, account_type, closest_airport
            ) VALUES (
                user_name, user_email, user_password, user_dob, user_address, user_city,
                user_state_id, user_zip, user_country_id, user_account_type, user_airport
            );
            
            SET i = i + 1;
        END WHILE;
        
        -- Commit the batch
        COMMIT;
        
        -- Output progress

			IF current_batch MOD 10 = 0 THEN
				SET @inserted = (current_batch + 1) * batch_size;
				IF @inserted > num_records THEN
					SET @inserted = num_records;
				END IF;
				
				SELECT CONCAT('Inserted ', @inserted, ' of ', num_records, ' records (', 
							 ROUND(@inserted / num_records * 100, 2), '%)') AS progress;
			END IF;

        
        SET current_batch = current_batch + 1;
    END WHILE;
    
    SELECT CONCAT('Finished inserting ', num_records, ' records') AS result;
END //
DELIMITER ;

--  (insert 1 million records):
CALL insert_userinfo_data(1000000);

-- you gonna need it xD
truncate userinfo
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- procedure quivelent to the python script 

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
            -- Increment state_id every 100 records (like Python script)
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


--  (insert 1 million records):
CALL insert_userinfo_duplicate_data(1000000);
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------