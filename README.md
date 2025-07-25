# Understanding MySQL Query Plans

---

## 🔹 Why MySQL Creates a Query Plan Before Each Query

### 🔸 What’s a Query Plan?
A query plan is a step-by-step strategy chosen by the MySQL query optimizer for how it will execute a SQL query.

**Example:**
```sql
SELECT * FROM customers WHERE city = 'London';
```
Before running this, MySQL considers:
- Do I have an index on the `city` column?
- Is it better to scan the whole table or use the index?
- How many rows am I likely to return?

These questions help MySQL decide the most efficient way to run the query.

### 🔸 Why Is This Important?
Databases can produce the same result using different methods, but some are much faster. The query plan affects:
- Execution time
- CPU usage
- Disk I/O

---

## 🔹 What Does EXPLAIN Do?

The statement:
```sql
EXPLAIN SELECT * FROM orders WHERE customer_id = 5;
```
- Does **not** execute the query.
- Shows how MySQL plans to execute it.

It reveals:
- Whether it will use an index
- What type of join it will use
- How many rows it thinks it will process

This helps you identify slow parts of a query before running it.



---

## 🔹 Key Concepts Explained

### 🔸 Full Table Scan
MySQL reads every row in the table, checking if it matches the WHERE clause.

- ✅ OK for small tables
- ❌ Bad for large tables

**Example:**
```sql
SELECT * FROM employees WHERE department = 'Sales';
```
If there's no index on `department`, this will be a full table scan.

---

### 🔸 Index Access

Indexes help MySQL find rows faster.

#### 1. Covering Index
If the index has all the necessary data:
- ✅ Best-case scenario
- No need to read the actual table

**Example:**
```sql
-- Composite index on (first_name, last_name)
SELECT first_name, last_name FROM employees WHERE first_name = 'John';
```
If the index contains all selected columns, MySQL can answer the query from the index alone.

#### 2. Index Lookup + Table Access
The index is used to filter rows, then the table is accessed for additional data.

**Example:**
```sql
SELECT salary FROM employees WHERE first_name = 'John';
```
If the index is on `first_name`, MySQL finds matching rows using the index, then fetches `salary` from the table.

---

### 🔸 Trade-Offs

If many rows are selected, jumping between index and table can be slower than a full scan. The optimizer chooses the lowest cost option based on:
- Table size
- Row estimates
- Index availability
- Requested columns

---

## 🔹 Tools for Analysis

### 🔸 EXPLAIN
**Syntax:**
```sql
EXPLAIN  SELECT * FROM CITY WHERE NAME = 'London';
```
- Shows expected execution plan
- Safe to run (no data is modified)

### 🔸 EXPLAIN ANALYZE (MySQL 8+)
**Syntax:**
```sql
EXPLAIN ANALYZE SELECT * FROM CITY WHERE NAME = 'London';
```
- Actually runs the query and shows what MySQL expected vs. what happened
- ⚠️ For `DELETE`, `UPDATE`, or `INSERT`, it will change data

**Examples:**
```sql
EXPLAIN DELETE FROM city;           -- Safe, only shows the plan
EXPLAIN ANALYZE DELETE FROM city;   -- Dangerous, will actually delete rows!
```

### 🔸 Optional Formats: FORMAT=...
MySQL supports output formatting:
```sql
EXPLAIN FORMAT=JSON SELECT * FROM orders;
```
- TRADITIONAL (default): table format
- JSON: most detailed
- TREE: good for visualizing plan hierarchy

💡 **Tip:** Use `FORMAT=JSON` for automation or deeper stats.



## 🔹 Summary of Key Takeaways

| Concept           | Explanation                                      |
|-------------------|--------------------------------------------------|
| Query Plan        | Strategy chosen by MySQL to execute a query      |
| Optimizer         | Decides how to best retrieve data                |
| Full Table Scan   | Reads all rows — slow for large tables           |
| Index Lookup      | Reads index first, may skip table read           |
| Covering Index    | Index contains all needed data — fastest         |
| EXPLAIN           | Shows planned query steps                        |
| EXPLAIN ANALYZE   | Shows actual execution time and behavior         |
| FORMAT=JSON       | Shows deep query info in

---

# 🔹 Query Example1: Filtering on a Non-Indexed Column
> “We will execute a simple `SELECT` on the `city` table with a condition on a non-indexed column called `name`.”

```sql
EXPLAIN SELECT * FROM CITY WHERE NAME = 'London';
```

> so the result set will be :

| select_table | table | partitions | **type** | possible_key | key_len | ref    | rows | filtered | extra      | 
|:------------:|:------|:----------:|:--------:|:------------:|:-------:|:------:|------|:--------:|:----------:|
| SIMPLE       | CITY  | `NULL`     |  **ALL** | `NULL`       | `NULL`  | `NULL` | 4046 | 10.00    | Using where|



- name is not indexed
- Therefore, MySQL cannot use an index to quickly locate the matching row(s)
- It must scan all rows

### 🔸 Result:
#### ➡️ Full Table Scan (Access Type = ALL)


## 🔹 Understanding Access Types in EXPLAIN
> “The table access types show whether a query accesses the table using an index scan…”

The **Access Type** (in `EXPLAIN`) tells you how MySQL reads data from the table.


| Access Type      | Meaning                                 | Cost          |
| ---------------- | --------------------------------------- | --------------|
| `ALL`            | Full Table Scan                         | ❌ High      | 
| `index`          | Full Index Scan                         | Moderate      |
| `range`          | Range scan using index (e.g., `>`, `<`) | ✅ Good      |
| `ref` / `eq_ref` | Index Lookup by equality                | ✅ Very Good |
| `const`          | Query matches a single row              | ✅ Best      |
| `system`         | Table has only one row                  | ✅✅✅      |



