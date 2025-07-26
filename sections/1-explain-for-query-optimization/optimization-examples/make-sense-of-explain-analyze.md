# 🔍 Understanding Query Estimates and `EXPLAIN ANALYZE` in MySQL

## 📌 Key Questions to Ask When Reading Execution Plans

1. **Is the runtime shown by `EXPLAIN ANALYZE` justified?**
2. **If the query is slow, where are the runtime jumps?**

Looking at runtime jumps in the plan helps reveal performance bottlenecks.

---

## ⚠️ When the Optimizer Makes Poor Decisions

You should compare:

- **Estimates** vs. **Actual Costs**

A **big difference** usually means the **optimizer’s statistics are outdated or inaccurate**.

> ✅ Tip: Run `ANALYZE TABLE` to refresh table statistics.

---

## 🧪 Experiment: Overestimation Due to Expression

We switch to a clean database and create a test table.

> **Step 1: Create table with primary key and index**
> 
> ```sql
> CREATE TABLE test_estimates (
>     id INT AUTO_INCREMENT PRIMARY KEY,
>     val INT,
>     val2 INT
> );
> 
> ALTER TABLE test_estimates ADD INDEX idx(val);
> ```

---

> **Step 2: Insert 100,000 rows using a Python script**
> 
> ```python
> queries = [
>   ("INSERT INTO `test_estimates` (`val`, `val2`) VALUES (?, ?)",)
> ]
> 
> for x in range(0, 100000):
>     for query in queries:
>         sql = query[0]
>         result = session.run_sql(sql, (x, x,))
> ```

---

> **Step 3: Analyze table to refresh statistics**
> 
> ```sql
> ANALYZE TABLE test_estimates;
> ```

---

> **Step 4: Run query with expression in WHERE clause**
> 
> ```sql
> EXPLAIN ANALYZE SELECT * FROM test_estimates WHERE 2 * val < 3;
> ```

---

## 🧠 Problem: Expression in WHERE Clause Ignores Index

Although there’s an index on `val`, the query does:

- ❌ **Not use the index**
- ❌ **Scans the full table**

📌 **Reason**: MySQL has statistics on columns, not expressions.

This leads to:

- Major **overestimation**
- Optimizer assumes **full table scan is cheaper**

---

## ✅ Solution: Add Functional Index

> **Step 5: Add index on expression**
> 
> ```sql
> ALTER TABLE test_estimates ADD INDEX idx_func((2 * val));
> ```

> **Step 6: Re-analyze and re-run query**
> 
> ```sql
> ANALYZE TABLE test_estimates;
> 
> EXPLAIN ANALYZE SELECT * FROM test_estimates WHERE 2 * val < 3;
> ```

💡 Now MySQL can use the functional index and avoid scanning the entire table.

---

## 🔍 Key Takeaways

- Pay close attention to:
  - **Estimated rows** vs. **Actual rows**
  - **Estimated cost** vs. **Actual cost**
- A large difference is a red flag:
  - ❗ The optimizer made wrong assumptions
  - ❗ The plan might be inefficient

---

## 🧊 Cold vs 🔥 Hot Cache


### 🔥 Hot Cache
- Data is already in memory (RAM or CPU cache).
- Access is very fast because there's no disk I/O.
- It means the system has recently used this data, so it's "hot".
- Example:
  - A frequently used query whose result is cached in memory.
  - Index pages or rows accessed multiple times stay hot.

&nbsp;

### ❄️ Cold Cache
- Data is not in memory — must be loaded from disk.
- Access is slower due to disk I/O.
- Happens when:
  - The system restarts (memory cleared).
  - The data hasn't been accessed recently.
  - The cache was evicted due to space limits.
- First-time access after restart usually faces cold cache performance.




> First query run = **cold cache** (slower)
> Second run = **hot cache** (faster)

> **Why?** Data is now in memory (MySQL/OS cache).

✅ You can check for hot cache behavior by:
- Running the same query multiple times
- Checking for consistent execution times

---

## 🛠️ Summary: What `EXPLAIN ANALYZE` Tells You

- A profiling tool that shows:
  - Where MySQL spends time
  - Row counts and timing at each step
- Helps you understand the **actual execution path**
- Lets you optimize based on **reality**, not assumptions
