# 📘 Composite Index Best Practices in MySQL

Understanding how to use composite (multi-column) indexes in MySQL is critical for writing high-performance queries, especially when filtering using multiple columns.

---

## 🔹 1. What is a Composite Index?

A **composite index** is an index on **two or more columns**. It improves performance when queries use **multiple columns together** in the `WHERE`, `ORDER BY`, or `GROUP BY` clauses.

---

## 🔸 2. Inefficient Index Design

> CREATE TABLE t (
>     c1 INT,
>     c2 INT,
>     c3 INT,
>     KEY (c1),
>     KEY (c2),
>     KEY (c3)
> );

❌ This design creates **three separate indexes**, but **none help** if the query filters on **multiple columns together** (like `c1 AND c2`).  
> [!NOTE]
> Each index only optimizes for queries that **use one column**.

---

## 🔸 3. Query Example (City Table)

> SELECT ID, Name, District, Population  
> FROM world.city  
> WHERE CountryCode = 'DEU'  
>   AND Population > 100000;

- With default indexes on `CountryCode` and `Population` **separately**, MySQL:
  - May only use **one index**.
  - Might need to scan many rows matching `CountryCode`, then filter `Population` manually.
> [!NOTE]
    > Some of DBMS might combine both indexes (on CountryCode and Population) in some form, either via an index merge or a bitmap index, depending on the DBMS and its query optimizer **but this is not the best practice**.



### 💡 Optimal Solution: Composite Index

> ALTER TABLE world.city  
> ADD INDEX idx_countrycode_population (CountryCode, Population);

✅ This allows MySQL to **efficiently filter using both columns together**, which greatly improves query performance.

### 🧠 Index Prefix Rule

MySQL can use:
- `(CountryCode)`
- `(CountryCode, Population)`
but **not just `(Population)`** from this index.

This is known as the **leftmost prefix rule** — MySQL uses the index **only if the leftmost columns are included** in the query.




---

## 🧪 Benchmark Examples

Let’s explore different index scenarios.
[✔ Benchmark of using different type indeces](/sections/2-composite-index-best-practices/benchmark/index-effect-examples.md)

---


## ⚠️ 4. Important Rule: Equality vs Range in Indexes

> CountryCode = 'DEU'  
> Population > 100000

- `CountryCode` uses an **equality condition**.
- `Population` uses a **range condition** (greater than `100000`).

### 🧠 Why This Matters

In MySQL:
- Once a column in a composite index is used for a **range condition** or **sorting**, the **remaining columns are not used** for index filtering.
- This means if `Population` came **before** `CountryCode` in the index, MySQL would **not** use the `CountryCode` part efficiently.

✅ Therefore, **the column with the equality condition should come first** in the composite index:

> ALTER TABLE world.city  
> ADD INDEX idx_countrycode_population (CountryCode, Population);

This lets MySQL use **both columns** efficiently in the query.

---

## 🔄 5. Index Can Be Used for Sorting

The same index:

> (CountryCode, Population)

can also be used for **sorting** the result by `Population`:

> SELECT *  
> FROM world.city  
> WHERE CountryCode = 'DEU'  
>   AND Population > 100000  
> ORDER BY Population;

✅ This works **only if** the index starts with the equality-filtered column (`CountryCode`), followed by the column used for sorting (`Population`).

---

## ✅ 6. Best Practices for Composite Indexes




> When all columns are used with **equality conditions**, consider:

| Factor | Description |
|--------|-------------|
| ✅ Use composite indexes for queries with multiple filters | e.g., `WHERE col1 = ? AND col2 = ?` |
| ✅ Order columns by selectivity and usage | Put more **selective** columns first |
| ✅ Use the **leftmost prefix rule** | Index `(a, b, c)` can support filters on `(a)`, `(a, b)`, or `(a, b, c)` |
| ❌ Avoid redundant indexes | Don’t create single-column indexes if already included in a composite index |

Index columns should be **ordered by:**
1. Most frequently queried
2. Most selective


> When all columns are used with **equality conditions**, consider:

| Factor | Description |
|--------|-------------|
| 🔄 Frequency | Which column is most commonly queried |
| 🧪 Selectivity | How well the column filters data (more unique = better selectivity) |

---

## 📈 Performance Benefit

With the composite index:

> (CountryCode, Population)

the query:

> SELECT ID, Name, District, Population  
> FROM world.city  
> WHERE CountryCode = 'DEU' AND Population > 100000;

Becomes an **index range scan**, significantly faster than a full table scan.

Use `EXPLAIN` to verify:

> EXPLAIN SELECT ID, Name, District, Population  
> FROM world.city  
> WHERE CountryCode = 'DEU' AND Population > 100000;

Look for:

- `key: idx_countrycode_population`
- `type: range`
- `rows: lower value`

---

## 📌 Summary

- Use **composite indexes** to filter by multiple columns.
- Always place **equality conditions first**, then **range conditions**, in index order.
- The **leftmost prefix rule** means only the **leading part** of the index can be used.
- Composite indexes can also be used for **sorting**, when column order matches.



---

# 🔁 Redundant Indexes in MySQL

In most cases, **redundant indexes** should be avoided. Instead of creating new indexes, we can often extend existing ones.

However, there are **exceptions** where redundant indexes improve performance, especially if extending an index leads to inefficiencies (like bloated size or poor performance on certain queries).

&nbsp;

## 🧠 What Are Redundant Indexes?

- If you have an index on `(a, b)` and another on `(a)`, the second is **redundant**, because `(a)` is a prefix of `(a, b)`.
- But an index on `(b, a)` or `(b)` is **not redundant**, since they don’t share the same leftmost prefix.

> Index on `(a, b)` → makes `(a)` redundant  
> Index on `(b, a)` → not redundant  
> Index on `(b)` → not redundant

**Special Note:** Indexes of different types (e.g., `FULLTEXT`, `HASH`) are **never redundant** to `BTREE` indexes.

---

## 🧪 Benchmark Example

Let’s explore when redundant indexes might be useful.
[ ✔ Benchmark of using redundant indeces](/sections/2-composite-index-best-practices/benchmark/redundant-indeces.md)

---


## 🔍 Identifying Redundant Indexes

Use the `sys` schema view to find them:

> SELECT * FROM sys.schema_redundant_indexes;

Example result:

| Table     | Redundant Index | Dominant Index           |
|-----------|------------------|--------------------------|
| userinfo  | idx_state_id     | idx_state_city_address   |

---

## 🧩 When Do Redundant Indexes Appear?

They often arise when:
- Someone adds a new index `(a, b)` instead of extending `(a)`
- An index covers `(a, id)`, where `id` is already part of the `PRIMARY KEY`

Note for **InnoDB** (default engine):  
An index on `a` is effectively `(a, id)`, because the `PRIMARY KEY` is appended internally.

---

## 📈 Index Order & Sort Performance

Given this query:

> SELECT state_id, city, address FROM userinfo WHERE state_id = 5 ORDER BY id;

If you create `idx(state_id)`, it behaves like `idx(state_id, id)` due to InnoDB.  
If you instead define `idx(state_id, city)`, it becomes `idx(state_id, city, id)`, and **sorting by `id` won't use the index** — a **filesort** will be triggered.

---

## ❌ Common Mistakes

- Indexing **all columns separately**  
- Indexing **columns in the wrong order**  
- Assuming **InnoDB** doesn't append the `PRIMARY KEY` to secondary indexes

---

## ✅ Summary

- Redundant indexes **can** be useful — when specific queries depend on them.
- Always **benchmark both queries and write operations** before deciding.
- Use `sys.schema_redundant_indexes` to identify them.
- For read-heavy workloads, maintaining multiple indexes may be justified.
- For write-heavy workloads, avoid redundant indexes unless necessary.

---


## 🔚 Extra Notes

- `idx(A)` = `idx(A, id)` (InnoDB behavior)
- `idx(state_id)` = `idx(state_id, id)`
- If you define `idx(A)` and then `idx(A, B)`, it becomes `idx(A, B, id)`
