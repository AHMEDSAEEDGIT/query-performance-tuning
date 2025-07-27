# 📌 Understanding When and Why to Use Secondary Indexes in MySQL

In this guide, we explore **why secondary indexes are important**, how **MySQL uses them**, when **not to use them**, and how to **interpret query behavior** with and without indexes using `EXPLAIN ANALYZE`.

---

## 🔍 What Is a Secondary Index?

A **secondary index** is any index that is **not the primary key**. It:

- Can contain **duplicate values**
- Is used to **speed up queries** that filter or sort data
- Helps **reduce I/O** by avoiding full table scans

> ✅ Key Point: When a query needs to find rows, MySQL has two strategies:
> - Full table scan (read every row in the table)
> - Index access (jump to matching rows via an index)

Secondary indexes are especially powerful when the **filter is highly selective** — that is, it narrows down the results to a small subset.

---

## 📈 Use Cases for Secondary Indexes

![ ✔ Secondary index](/sections/4-index-performance/imgs/1.jpg)


### 1. Filtering Rows (`WHERE` or `JOIN`)

When you filter rows (e.g., using a `WHERE` condition), a good index can help MySQL **avoid scanning the entire table**.

**Example:**
```sql
 EXPLAIN ANALYZE SELECT * FROM payment WHERE amount = '10.99';
```

If there is **no index** on `amount`, MySQL will perform a **full table scan**, which is slow on large datasets.

&nbsp;

### 2. Sorting Rows (`ORDER BY`)

Indexes can also be used to **return sorted results** without doing an extra sort.

**Example:**
```sql
 EXPLAIN ANALYZE SELECT * FROM payment ORDER BY amount DESC LIMIT 10;
```

Without an index on `amount`, MySQL:
- Scans the full table
- Then sorts the results (which took 11ms in the video example)

&nbsp;


### 3. Fixing the Above with an Index

Let’s add an index on the `amount` column:

```sql
ALTER TABLE payment ADD INDEX idx_amt(amount);
```
Now:
- The first query (filtering) uses the index and runs **faster**
- The second query (sorting) uses the index to return sorted results **directly**, no extra sorting needed

---

## 🛠️ Other Use Cases for Indexes

### ✅ Enforcing Uniqueness

You can use **unique indexes** to ensure a column or combination of columns only allows **distinct values**.

 **Example:**
```sql
 CREATE UNIQUE INDEX idx_unique ON table_name(col1, col2);
```
&nbsp;


### ✅ Covering Indexes (Index-Only Reads)

If a query only needs data that exists **within the index**, MySQL can **skip reading the full row** from disk.

> This improves performance because:
> - MySQL reads only the index page (smaller and cached)
> - It avoids loading unnecessary columns

&nbsp;


### ✅ Finding Min/Max Values

Because index data is **sorted**, MySQL can quickly find `MIN` and `MAX` without scanning all rows.

 **Example:**
```sql
 EXPLAIN ANALYZE SELECT customer_id, MAX(amount) FROM payment GROUP BY customer_id LIMIT 10;
```
This will efficiently find the max `amount` per customer using the index.

---

## ❓ Should You Always Add an Index?

Not always. You should ask:

1. Is the query filtering, joining, or sorting on a column?
2. Will the index reduce scanned rows?
3. Will it help enforce uniqueness or improve grouping?

Adding indexes has tradeoffs:
- **Improves reads**, but
- **Slows down writes (INSERT/UPDATE/DELETE)**
- **Consumes disk space**

---

## ⚠️ Final Advice

- Use `EXPLAIN ANALYZE` to **confirm the index is being used**
- Avoid adding too many indexes — they can degrade write performance
- Maintain your indexes regularly
- Indexes are most useful when:
  - The column is **selective** (many unique values)
  - The column is **frequently filtered, sorted, or grouped**

> ⚠️ Good indexes can improve performance by **orders of magnitude** — bad ones can slow things down.

---

# ⚙️ Index Maintenance and Performance Monitoring in MySQL

Index maintenance is a **continuous responsibility** — it doesn't stop after creation. As your application grows and data changes, indexes require ongoing attention and evaluation to ensure they remain beneficial.



## 🧠 Why Are Indexes Costly?

Indexes are not "free". While they improve query performance, they also:

- Consume **memory** (in cache and buffers)
- Consume **CPU cycles** (especially during writes)
- Require **ongoing maintenance** (e.g., rebuilding, rebalancing B-trees)

---

## 💡 How Do Indexes Lock CPU and Memory?

When indexes are used, MySQL has to **maintain the structure of the index** (usually a B-tree). This involves:

- **Memory Usage**
  - InnoDB caches parts of the index in the **buffer pool**.
  - The more indexes you have, the more memory is needed to keep them cached.
  - Unused indexes may still reside in memory and waste space.

- **CPU Usage**
  - On every `INSERT`, `UPDATE`, or `DELETE`, MySQL must:
    - Locate where the change occurs in the index
    - Rebalance the B-tree structure if necessary
    - Lock and write index nodes to disk
  - Complex indexes or frequent writes mean more CPU cycles are used per operation.

> ⚠️ The more indexes you have:
> - The slower the **write performance**
> - The higher the **memory consumption**
> - The more **CPU resources** needed to maintain them

---

## 📊 How to Measure Index Usefulness

To decide if an index is **worth keeping**, you need to collect **statistics**. MySQL provides useful views in the `sys` schema for this.

&nbsp;

### 🔎 Find Tables Doing Full Table Scans

Use this view to see which tables are **reading rows without using any index**.

```sql
 USE sys;  
 SELECT * FROM schema_tables_with_full_table_scans;
```

- The results are sorted by number of rows read (descending).
- Focus on tables with **millions of rows scanned** — they are most likely to benefit from an index.

&nbsp;

### 📄 Find Statements Doing Full Table Scans

Use this view to identify **queries** that don’t benefit from indexes.

```sql
 SELECT * FROM statements_with_full_table_scans;
```

- It shows **normalized queries** (e.g., placeholders instead of literals)
- It orders queries by:
  - Number of times run **without any index**
  - Number of times run **without a good index**

📌 Use this view to find **repeated inefficient queries** and determine if a new index could help.

---

## 🔍 Cleaning Up: Unused or Redundant Indexes

Extra indexes come at a cost. If they are no longer used, it’s best to remove them.

### 🚫 Find Unused Indexes

This view shows indexes that **have not been used** recently (or ever):

```sql
 SELECT * FROM schema_unused_indexes;
```
- Includes table and index name
- Helps you safely drop unnecessary indexes

&nbsp;

### 📛 Find Redundant Indexes

Sometimes developers accidentally create multiple indexes on the same column(s), or overlapping ones.

```sql
 SELECT * FROM schema_redundant_indexes;
```
- This view finds indexes that **provide no additional benefit**
- MySQL may still maintain them, **wasting CPU and memory**

---

## ✅ Final Advice

- Use the `sys` and `performance_schema` views regularly to **audit** index usage
- Don’t blindly add indexes — use statistics to **prove their value**
- Periodically **clean up** unused or duplicate indexes
- Balance index creation with:
  - Read speed
  - Write overhead
  - Memory/CPU cost

> Indexing is a trade-off between **read performance** and **write/memory/CPU cost** — and the right balance changes as your system evolves.

---

# 🧠 How MySQL Decides Whether to Use an Index or Not

MySQL uses its **query optimizer** to decide whether to use an index or perform a full table scan. This decision depends on the **estimated cost** of each option, not just the existence of the index.

&nbsp;

## 🔄 Secondary Index vs. Table Scan

### 🧱 Secondary Indexes
- Do **not** contain the full row data (unless it's a covering index).
- Only store:
  - The indexed columns
  - A pointer to the **primary key**
- So for each match:
  - MySQL must perform a **secondary lookup** using the primary key to retrieve the full row.
  - This adds overhead, especially when fetching many rows.

### 📋 Table Scans
- Read all rows in the table **sequentially**.
- In general, sequential I/O is:
  - **Faster** than random I/O
  - More efficient for **large reads**

---

## ⚖️ When Is a Table Scan Better?

Even though indexes are often faster, there are situations where a full table scan wins:

- The query **retrieves a large percentage** of the table rows.
- The table is **small enough** to read quickly in memory.
- The data is **already cached** in the buffer pool.
- Your **disk has high sequential I/O performance** but slow random access.

![ ✔ Secondary index](/sections/4-index-performance/imgs/3.jpg)
> [!NOTE]
> **Example Rule of Thumb** (from spinning disk days):
> If a query retrieves more than **30%** of the table's rows, then a **table scan** is typically faster than using a secondary index.



> [!NOTE]
> With SSDs and large buffer pools, this threshold might be higher (e.g. 50–70%), depending on hardware and workload.

---

## 🎯 How MySQL Chooses: Index Selectivity

The key factor MySQL cares about is **selectivity**:
> **Selectivity** = fraction of table rows filtered out by the index

- High selectivity = index filters **many** rows → Good index candidate
- Low selectivity = index filters **few** rows → Table scan likely better

---

## 📊 What Are Index Statistics?

MySQL uses **index statistics** to estimate selectivity and decide on execution plans.

- Statistics describe the **distribution of values** in the index.
- They are **approximate**, not exact.
- For example, they might say:
  - "90% of values in `country_code` = 'US'"
  - or "Column `status` only has 3 distinct values"

These are **used by the optimizer** to answer:
- How many rows will match the `WHERE` condition?
- Will this index reduce the number of rows enough to be worth using?

---

## 🧱 Where Do These Statistics Come From?

In MySQL (specifically InnoDB):

- The **storage engine** is responsible for gathering and maintaining index statistics.
- These are gathered:
  - **Automatically**, during query execution
  - Or manually via:
    ```sql
     ANALYZE TABLE your_table;
    ```
- InnoDB stores index statistics in:
  - `mysql.innodb_table_stats`
  - `mysql.innodb_index_stats`

> These are internal metadata tables that hold estimates of cardinality and data distribution.

---

## 🔍 Summary

| Factor                          | Index | Table Scan |
|-------------------------------|-------|-------------|
| Filters many rows             | ✅    | ❌          |
| Small table / large result set| ❌    | ✅          |
| Sequential I/O                | ❌    | ✅          |
| Random I/O                    | ✅    | ❌          |
| Rows mostly in buffer pool    | Depends| ✅         |

MySQL uses **index statistics** to estimate these trade-offs and determine whether the index will be efficient for the query. Knowing how this works can help you:

- Understand why MySQL may **ignore your index**
- Improve queries by **analyzing selectivity**
- Decide when to **force an index** or restructure queries
---

# 🔍 How InnoDB Index Statistics Work

InnoDB calculates its **index statistics** by analyzing a small sample of **random leaf pages** from the index. For example, it may take 20 random samples—this process is referred to as **"index dives"**. In each sampled page, it looks at the values it contains, then **scales** that information based on the total size of the index.

![ ✔ index dives](/sections/4-index-performance/imgs/6.jpg)


&nbsp; 

### ❗ Why Use Estimates Instead of Exact Statistics?

- **Performance:** Gathering precise statistics would require scanning the entire index, which is too costly.
- **Tradeoff:** InnoDB samples a small number of pages to balance performance and accuracy.

As a result:

- These statistics are **approximate**, not exact.
- **Downside:** They may poorly reflect the actual data distribution.
  - This can lead to **poor decisions by the optimizer**:
    - Wrong index choice.
    - Wrong join order.
    - Slower queries.

### ⚙️ Persistent vs. Transient Statistics

There are two modes of handling index statistics:

![ ✔ Secondary index](/sections/4-index-performance/imgs/7.jpg)

#### ✅ Persistent Statistics

- Preferred by default.
- Provide more **consistent query plans**.
- Allow **more pages to be sampled**.
- Updated **in the background**.
- Allow **table-level customization** (via `STATS_SAMPLE_PAGES`).
- Controlled by:
  
  > show variables like 'innodb_stats_persistent_sample_pages';

#### 🔁 Transient Statistics

- Temporary (non-persistent).
- Controlled by:

  > show variables like 'innodb_stats_transient_sample_pages';

- Less flexible.
- Can also be overridden using **table-specific options**.

&nbsp;

### 🛠️ Table-Level Configuration

You can customize how many pages are sampled using the `STATS_SAMPLE_PAGES` option.

Example when creating a table:

```sql
 CREATE TABLE tbl(  
 ID   INT NOT NULL AUTO_INCREMENT,  
 NAME CHAR(20),  
 INDEX NAME_IDX(NAME)  
 )  
 STATS_SAMPLE_PAGES = 25;
```

**Or modifying an existing table:**

```sql
 ALTER TABLE tbl STATS_SAMPLE_PAGES = 25;
```

---

### 🧠 How Many Pages Should Be Sampled?

- **Uniform Data Distribution**:
  - Few pages needed.
  - Default sample size is usually fine.
- **Irregular Data Distribution**:
  - Increase the number of pages.
  - Example: A queue where most rows have the same status (e.g., `completed`).
  - All sampled pages might show only one value, making the index **seem useless** even when it’s not.

> ⚠️ This leads to **inaccurate statistics** → Optimizer ignores a potentially useful index.

---

### 🧱 Table Size Also Matters

- **Larger tables** require **more sampled pages**:
  - To avoid the risk of sampling only similar values.
  - Leaf pages in large tables may be filled with identical values.

---

### ⚖️ The Tradeoff: Accuracy vs. Cost

- **More sampled pages** = **Better statistics**, **slower ANALYZE TABLE**.
- The cost shows up during:

```sql
   ANALYZE TABLE your_table;
```

- This command is run automatically when:
  - More than **10% of table rows change**.

#### 📉 If `ANALYZE TABLE` is too slow:

- Decrease `STATS_SAMPLE_PAGES`.
- Set at the table level (not just globally).

---

### ✅ Summary

| Factor | Recommendation |
|-------|-----------------|
| Consistent performance | Use persistent statistics |
| High data skew | Increase sample pages |
| Large table | Increase sample pages |
| Analyze is slow | Decrease sample pages |
| Need custom tuning | Use `STATS_SAMPLE_PAGES` in `CREATE` or `ALTER` |


