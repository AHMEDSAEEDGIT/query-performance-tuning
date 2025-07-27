# 📏Measuring Query Performance in MySQL

When we encounter a performance problem, the first step is to determine what is causing it. Our goal is to reduce the response time, and therefore, we need to understand why the server requires a certain amount of time to respond to a query.

This leads to an important principle of optimization: **we cannot reliably optimize what we cannot measure**. So, our first job is to **measure where the time is spent**, then reduce or eliminate whatever unnecessary work is being done to achieve the results.

![ ✔ MySQL performance measurement](/sections/7-spotting-performance-problems/imgs/1.jpg)

MySQL offers a large set of system views that allow administrators and developers alike to take a deeper look into what is really going on in their system. There is **no way to improve performance and reliability without first collecting the necessary data**. Afterward, we can make educated decisions based on facts.

One of the most powerful tools for this purpose is the **Performance Schema**, a goldmine when it comes to information about the performance of your queries.

To begin exploring it:

```sql
 USE performance_schema;  
 SHOW TABLES;
```

The objective is to make use of MySQL statistics and gain actionable insights. These tables provide **very detailed information about the queries** executing on the instance.

The most commonly used table is:

- `events_statements_summary_by_digest`

This is essentially a report of **all the queries that have been executed** on the instance since the table was last reset (which normally happens when MySQL is restarted).

To view its content:

```sql
 SELECT * FROM events_statements_summary_by_digest;
```

However, this output has a lot of noise. A good way to sort it would be by **total execution time**, represented by the field `SUM_TIMER_WAIT`, which equals the number of times the query was executed multiplied by the average execution time.

To get the top 10 most expensive queries:

```sql
 SELECT * FROM events_statements_summary_by_digest  ORDER BY SUM_TIMER_WAIT DESC  LIMIT 10;
```
&nbsp;
## ✅ Important Fields to Understand

- **`DIGEST_TEXT`**: Contains the normalized query text  
  - Example:  
    - `SELECT * FROM city WHERE name = 'Paris';`  
    - `SELECT * FROM city WHERE name = 'London';`  
    - Both become → `SELECT * FROM city WHERE name = ?;`

- **`COUNT_STAR`**: Number of times the query was executed

- **`SUM_TIMER_WAIT`**: Total time spent executing this query

- **`SUM_LOCK_TIME`**: Total time spent waiting for table locks

Other columns might reveal **optimization opportunities** depending on the context. For instance:

- If monitoring shows issues with internal temporary tables using a lot of memory or disk, look at:
  - `SUM_CREATED_TMP_DISK_TABLES`
  - `SUM_CREATED_TMP_TABLES`
  - `SUM_CREATED_TMP_FULL_TABLES`

These fields can help identify problem areas when the root cause of performance degradation is not yet known.

---

# 🔍 Identifying the Top Time-Consuming Queries in MySQL

A good place to start optimizing is by identifying the **top 10 most time-consuming queries**. Just running a simple `SELECT` on the view won't be very helpful — even normalized queries can be very numerous. That’s why it's best to sort the output so that the most relevant information stands out.

Here is a custom query that sorts and ranks the most expensive queries:

```sql
 SELECT  
   (100 * SUM_TIMER_WAIT / SUM(SUM_TIMER_WAIT) OVER ()) AS percent,  
   SUM_TIMER_WAIT AS total,  
   COUNT_STAR AS calls,  
   AVG_TIMER_WAIT AS mean,  
   SUBSTRING(DIGEST_TEXT, 1, 75)  
 FROM performance_schema.events_statements_summary_by_digest  
 ORDER BY SUM_TIMER_WAIT DESC  
 LIMIT 10;
```

![ ✔ most expensive queries](/sections/7-spotting-performance-problems/imgs/2.jpg)

### What This Query Shows

Each row includes:
- **Total response time** (in picoseconds)
- **Response time as a percent** of overall query latency
- **Number of executions** of the query
- **Average execution time** per query
- **A truncated (abstracted) version of the query**

This output helps clarify:
- Which query types are the most expensive
- How expensive each one is **relative to others**
- Their impact on **total system load**

Checking the **top 1000 queries** is often **not useful**, as they contribute very little to total system latency. Typically, just a **handful of queries** are responsible for the majority of system load.

---

### Viewing a More Human-Readable Summary

The above view returns timings in **picoseconds** (10⁻¹² seconds), which isn’t easy for humans to interpret.

Instead, use the **`sys` schema**, which provides prebuilt and more readable reports.

For example:

```sql
 SELECT * FROM sys.statement_analysis   LIMIT 10;
 ```

This version is already **ordered by total latency in descending order**, making it easier to digest.

![ ✔ most expensive queries](/sections/7-spotting-performance-problems/imgs/3.jpg)


> [!NOTE]
> `sys` views are based on the `performance_schema` but come with a limitation:  
> They cannot be customized or extended easily.

---

### Going Back to Raw Performance Schema

If you want full flexibility to drill deeper into problems, go back to the raw `performance_schema` table:

```sql
 SELECT *  
 FROM performance_schema.events_statements_summary_by_digest  
 ORDER BY SUM_TIMER_WAIT DESC  
 LIMIT 10;
```

While this helps identify **which activities are consuming time**, it **doesn’t explain why**.

### Example: Digging Deeper

If a `SELECT` statement takes too long, the delay might not be due to CPU usage, but due to **I/O waits** — such as fetching a large data set only to filter most of it out later.

To investigate **why** a query takes time, you need to **drill into the state** and

---

# 🔍 Why Are Queries Slow?

Queries can be slow for several reasons, but ultimately, it comes down to how efficiently the database handles each step in the query's lifetime.

## Query Execution as Sub-Tasks

![ ✔ split query into subtasks](/sections/7-spotting-performance-problems/imgs/4.jpg)


A query is composed of several **sub-tasks**. These sub-tasks can be:
- Eliminated
- Made to happen fewer times
- Made to run faster

Understanding and optimizing these sub-tasks is key to query performance.

&nbsp;

## 🔄 The Query Lifecycle 

A typical query flows through the following stages:

1. **Client to Server**
2. **Parsing**: MySQL checks for valid SQL syntax.
3. **Planning**: MySQL creates an execution plan (based on statistics, indexes, etc.).
4. **Execution**:
   - Calls to storage engine to **retrieve rows**
   - **Post-retrieval operations**: filtering, sorting, grouping
   - These involve time spent in:
     - CPU (e.g., planning, sorting)
     - Network (sending/receiving data)
     - Memory (caching, temp tables)
     - **Disk I/O** (if data isn't cached)
5. **Server to Client**: Results are returned.

---

## ⚙️ Execution is Often the Bottleneck

The most time-consuming part is often **execution**, especially:
- Repeated **calls to storage engine**
- **Sorting** or **grouping** large datasets
- Using inefficient **access paths** (e.g., full table scan vs index)

---

# ✔ Optimization Goals

The goals of optimization are to:
- Eliminate unnecessary operations
- Reduce the number of times operations are executed
- Make operations faster (e.g., using better indexes, caching)

&nbsp;

## Common Performance Problems (and Metrics to Investigate)

We can use Performance Schema and metrics from views like `events_statements_summary_by_digest` to investigate.

```sql
 SELECT * FROM events_statements_summary_by_digest ORDER BY SUM_TIMER_WAIT DESC LIMIT 3;
 ```

### 🔹 1. **Large number of examined rows vs. rows returned**
- **Metrics**: `SUM_ROWS_SENT` vs `SUM_ROWS_EXAMINED`
- **Implication**: Poor index usage.
- **Example**: Many rows are scanned, but few are returned.

&nbsp;

### 🔹 2. **High number of full joins**
- **Metric**: `SUM_SELECT_FULL_JOIN`
- **Cause**: 
  - Missing join conditions
  - Missing indexes
- **Effect**: Full table scans on joined tables.

&nbsp;

### 🔹 3. **High range check count**
- **Metric**: `SUM_SELECT_RANGE_CHECK`
- **Cause**: Indexes may need adjustment.
- **Effect**: Range scans touch too many rows.

&nbsp;

### 🔹 4. **Secondary index used inefficiently**
- **Problem**: Range scan on a secondary index covers a large portion of the table.
- **Effect**: Might be more expensive than full table scan.

&nbsp;

### 🔹 5. **High number of temporary tables on disk**
- **Metric**: `SUM_CREATED_TMP_DISK_TABLES`
- **Cause**: 
  - Insufficient memory for temp tables
  - Poor indexing for sorting/grouping
- **Effect**: Disk I/O is slower than memory.

&nbsp;

### 🔹 6. **High number of sort merge passes**
- **Metric**: `SUM_SORT_MERGE_PASSES`
- **Cause**: Sort buffer too small.
- **Solution**: Increase sort buffer size.

&nbsp;

### 🔹 7. **High CPU usage**
- May be caused by:
  - Large table scans
  - Inefficient queries
- Investigate using:

```sql
 SELECT * FROM schema_tables_with_full_table_scans;
```

**Then:**

```sql
 SELECT * FROM statments_with_full_table_scans ORDER BY NO_INDEX_USED_COUNT DESC;
```
---

## ✍ Summary

Query performance depends on:
- Execution efficiency
- Index quality and usage
- Table size and memory availability
- Disk vs memory I/O
- Buffer sizes

By analyzing metrics and breaking down the query execution path, you can identify which part is the bottleneck and optimize accordingly.

---

## 🔍 Investigating I/O Performance in MySQL

Disk I/O performance is **critical** to MySQL database performance. MySQL reads and writes data to disk in multiple areas, including:

- **Tablespaces**
- **Indexes**
- **Redo logs**
- **Binary logs**
- **Temporary files**

### 📌 When to Investigate I/O?

An **increase in I/O count or latency** is not automatically bad — it depends on the context. However, **if the disk becomes a bottleneck** (e.g., 100% disk utilization), it's time to investigate.

---

### 🛠 Useful Tools: `performance_schema`

MySQL provides views in the `performance_schema` that can help pinpoint **which tables or indexes** are contributing to I/O load.

To begin:

```sql
 USE performance_schema;
 SHOW TABLES;
```

---

### 📊 Analyzing Index Usage with I/O Stats

A particularly useful view is:

 `table_io_waits_summary_by_index_usage`

You can use it to find **how many reads were done using indexes** vs. reads that bypassed indexes.

**Example:**

```sql
 SELECT OBJECT_TYPE, OBJECT_NAME, INDEX_NAME, COUNT_STAR  
 FROM performance_schema.table_io_waits_summary_by_index_usage  
 WHERE object_schema = 'world'  
 AND object_name = 'city';
```
&nbsp;

![ ✔ most expensive queries](/sections/7-spotting-performance-problems/imgs/6.jpg)


### 🧠 What This Query Tells You

This will return how many rows were read from the `city` table in the `world` schema:

- **Rows read using a specific index** will be listed by index name.
- **Rows read without an index** will show `INDEX_NAME = NULL`.

If you observe that:
- Rows read using an index are **very few**
- Rows read with `INDEX_NAME = NULL` are **very high**

**Then it suggests:**
> ❗ The query is performing many full table scans (i.e., **no index** was used).

---

### 💡 What To Do With This Insight?

- Investigate whether the queries on that table **can use an index**.
- Check if an appropriate index **exists** for the query patterns.
- Consider **adding indexes** on columns frequently used in `WHERE`, `JOIN`, or `ORDER BY`.

&nbsp;

### ✅ Summary

- Use `performance_schema.table_io_waits_summary_by_index_usage` to analyze read patterns.
- Look for high I/O activity **without index usage**.
- Optimizing index usage can significantly reduce disk I/O and improve performance.

---


## 🔍 Understanding I/O Operations in MySQL with Performance Schema

Efficient **I/O (Input/Output) performance** is crucial for MySQL databases. Since data is frequently read from and written to disk—through table spaces, indexes, redo logs, binary logs, and more—monitoring I/O behavior helps identify potential bottlenecks.

#### 📌 Key Insight
An increase in I/O operations or latency **is not inherently good or bad**. It's only concerning if it's correlated with a performance problem, such as disk utilization being consistently near 100%.

&nbsp;

## 🧪 Investigating I/O Activity

To analyze what’s causing high I/O, MySQL provides performance monitoring tables:

```sql
 use performance_schema;
 show tables;
```

One particularly helpful view is:

```sql
 select OBJECT_TYPE, OBJECT_NAME, INDEX_NAME, COUNT_STAR  
 from performance_schema.table_io_waits_summary_by_index_usage  
 where object_schema = 'world'  
 and object_name = 'city';
```



This gives insight into how many times an index was used vs. not used for a given table (in this case, the `city` table in the `world` schema).

#### 🧠 Interpretation:
- When `INDEX_NAME` is `NULL`, it means the table scan **did not use an index**.
- If reads without indexes are **significantly higher**, it suggests **unnecessary full-table scans** are occurring—often a sign that you need a better indexing strategy.

---

### ⚙️ Experiment: Fetch, Insert, Update, and Delete Counters

Let’s examine I/O counters using real queries.

1. First, inspect the table and its indexes:

```sql
 use world;  
 desc city;
```

You’ll see:
- A **primary key** on the `id` column.
- A **secondary index** on the `countrycode` column.

---

### 📘 Example Queries

#### ✅ Primary Key Lookup (Optimized)

```sql
 select * from city where id = 5;
```

Then check I/O statistics:

```sql
 select *  
 from performance_schema.table_io_waits_summary_by_table  
 where object_name = 'city';
```

![ ✔ query result](/sections/7-spotting-performance-problems/imgs/7.jpg)


📊 **Result**: Only **1 row read** and **1 fetch**, because the `id` is indexed as the primary key.
---

#### 📘 Secondary Index Lookup

```sql
 select * from city where countrycode = 'NLD';
```

This returns 28 rows.

Check the statistics again:

```sql
 select *  
 from performance_schema.table_io_waits_summary_by_table  
 where object_name = 'city';
```

📊 **Result**: 29 rows read and 29 rows fetched – one per row returned.

---

#### ⚠️ No Index (Full Table Scan)
```sql
 select * from city where name = 'Amsterdam';
```

Only **1 row** is returned.

**But…**

```sql
 select *  
 from performance_schema.table_io_waits_summary_by_table  
 where object_name = 'city';
```

📊 **Result**: Over **4,000 rows read/fetched** — because `name` is **not indexed**. MySQL must scan the **entire table**.

---

#### 🛠️ Update Without Index

```sql
 update city  
 set name = 'Amsterdam1'  
 where name = 'Amsterdam';
```
Even though it updates **just one row**, the statistics still show over **4,000 rows** read and fetched—again, due to **no index** on `name`.

&nbsp;

### 🔍 Key Observations

| Operation | Index Used?     | I/O Behavior                     |
|-----------|------------------|----------------------------------|
| `SELECT` by `id`          | ✅ Primary Key   | Minimal I/O                 |
| `SELECT` by `countrycode`| ✅ Secondary Index | Proportional to matched rows |
| `SELECT` by `name`       | ❌ No Index       | Full table scan (high I/O)   |
| `UPDATE` by `name`       | ❌ No Index       | Full table scan (high I/O)   |

![ ✔ query result](/sections/7-spotting-performance-problems/imgs/8.jpg)

---

### ✅ Takeaways



- **Read-before-write**: Even **update** and **delete** statements trigger **reads** to locate target rows.
- **Secondary indexes** are better than no index—but **not as fast** as primary keys.
- Using no index causes full scans, impacting performance, especially on large tables.
- Always monitor I/O behavior using `performance_schema` to inform **index optimization**.

---

## ❗ Errors and Their Impact on Query Performance

While errors are **not directly related** to query tuning, they **do impact performance** in important ways:

#### ❌ Errors Still Use Resources
- When a query results in an **error**, it still **consumes CPU, memory, and disk I/O** up to the point of failure.
- The system performs the work **in vain**, resulting in wasted resources.

#### 🔄 Some Errors Are Performance-Related

![ ✔ error tables](/sections/7-spotting-performance-problems/imgs/9.jpg)


- Errors such as **failure to obtain locks** are more directly tied to performance issues.
- In **concurrent environments**, multiple requests may try to **update the same resource** (like a row in a table).
  - That row must be **locked** during the update.
  - If one request **takes too long**, it will **block others**, increasing **wait times** and **system contention**.

--- 
 
## 📊 Analyzing Errors in Performance Schema
MySQL provides **five error-related tables** in the `performance_schema` to help track and analyze errors:

![ ✔ error tables](/sections/7-spotting-performance-problems/imgs/10.jpg)


You can check for errors such as **deadlocks** using:

```sql
 select *  
 from events_errors_summary_by_account_by_error  
 where error_name = 'er_lock_deadlock';
```

This query will show:
- Which **accounts** encountered deadlocks
- How often it happened
- Which **host** and **user** triggered them

> [!NOTE]
>  If `user` and `host` are `NULL`, that row refers to **background threads**.

&nbsp; 

#### 🔍 What to Monitor for Query Health
When analyzing the performance schema, don’t limit yourself to query statistics alone. Look into:
- `events_statements_summary_by_digest` – for **problematic queries**
- `table_io_waits_summary_by_table` – for **I/O patterns**
- `events_errors_summary_*` – for **error patterns** (like timeouts and deadlocks)

By identifying queries that cause **errors**, especially under **heavy load**, you can reduce **resource waste**, prevent **lock contention**, and improve overall **system stability**.
