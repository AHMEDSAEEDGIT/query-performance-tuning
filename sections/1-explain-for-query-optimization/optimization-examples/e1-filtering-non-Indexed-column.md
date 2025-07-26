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

---

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



- Access Type = `ALL`
- Means MySQL reads **all rows** in the table (slow for big tables)

> “This type is written in **ALL CAPS** because it's the most expensive.”

---

## 🔹 Row Estimate and Filter Estimate
### 🔸 Estimated Rows:
> “It’s estimated that 4046 rows will be examined…”

This means:

- The city table has ~4046 rows
- MySQL expects to **scan all of them**

&nbsp;

### 🔸 Filter Estimate:
> “It's expected that 10% of the rows examined will match the where clause…”

- So, around 400–450 rows might match name = 'London' (even if that's not true).
- This is only an estimate based on internal stats.

> [!WARNING]
> MySQL uses default heuristics if no index/statistics are available — don’t rely on this for accuracy.


&nbsp;

## 🔹 Formats of EXPLAIN Output
MySQL supports 3 output formats:

| Format          | Description                    | Use Case                      |
| --------------- | ------------------------------ | ----------------------------- |
| **Traditional** | Tabular rows (default)         | Quick checks, human-readable  |
| **JSON**        | Rich details in JSON structure | Best for tools, scripting     |
| **TREE**        | Hierarchical execution steps   | Best for visual understanding |

> “The tree style is the newest format … shows execution order and relationships.”

---

## 🔹 Tree Format and EXPLAIN ANALYZE

> “The tree format is also the default for EXPLAIN ANALYZE as of MySQL 8.0.18.”

### 🔸 Example:

```sql
EXPLAIN ANALYZE SELECT * FROM city WHERE name = 'London';
```

This actually runs the query and:
- Shows which parts took more/less time
- Displays how many rows were returned from each step

```pgsql
-> Filter: (city.`Name` = 'London')  (cost=411 rows=405) (actual time=0.352..1.92 rows=2 loops=1)
     -> Table scan on CITY  (cost=411 rows=4046) (actual time=0.138..1.57 rows=4079 loops=1)
 
```

# 🔹 Understanding Tree Output Structure
> “The output is organized into a series of nodes…”

#### Think of it like a tree:
- Leaf Nodes: Actual scans (e.g., full table scan, index scan)
- Parent Nodes: Filtering, sorting, joining, etc.


So the steps are:

- Read all rows from city table
- Apply WHERE name = 'Cairo' filter



## 🔹 Estimated vs Actual Costs
> “The estimation cost is represented in internal MySQL units…”

You might see output like:

```json
"cost_info": {
    "query_cost": 37.50,
    "read_cost": 30,
    "eval_cost": 7.5
}
```

###  🔸 What does this mean?
- These are not milliseconds
- MySQL assigns a “cost” value to each operation
   - Reading from disk: cost = 2
   - Reading from memory: cost = 1

- They help the optimizer compare possible plans — lower cost is better.

&nbsp;

## 🔹 Actual Execution Timing
 > “The first row was read in about 4 milliseconds… all rows in roughly 5ms”

You may see this in output:

```json
"actual_time": {
  "first_row": 4.2,
  "last_row": 5.1
}
```


###  🔸 What does this mean?

- **First match** found after 4ms
- **All data** processed in 5ms

✅ Efficient for small tables, even with full scans
❌ But will be much slower with larger data

&nbsp;

### 🔹 Loops = Number of Executions
> “There was a single loop for this query because there was no join…”

This means:
- MySQL only ran this sub-step once
- If there was a JOIN, you'd see nested loops


---

# 🔹 Summary of Key Takeaways (This Example)

| Concept                  | Explanation                                              |
| ------------------------ | -------------------------------------------------------- |
| `Access Type = ALL`      | Full table scan, most expensive                          |
| No index on `name`       | Forces MySQL to read all rows                            |
| `EXPLAIN` output         | Shows estimated rows and filters                         |
| Traditional format       | Basic overview, useful for index visibility              |
| Tree format              | Hierarchical, shows execution order                      |
| `EXPLAIN ANALYZE`        | Shows actual execution time, row counts                  |
| Cost units               | Internal numbers used by MySQL to estimate performance   |
| First vs Last row timing | Helps analyze slow parts of a plan                       |
| Loops                    | Show how many times a step runs (esp. useful with joins) |
