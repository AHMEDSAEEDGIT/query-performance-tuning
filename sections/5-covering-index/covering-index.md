### 📌 Covering Indexes in MySQL

Even if an index is used for a query, this doesn't mean we can't still optimize it further. A **common suggestion** is to create indexes based on the `WHERE` clause — but that's only part of the story.

Indexes should be **designed for the entire query**, not just filtering. MySQL can use indexes **not only to find rows efficiently**, but also to **retrieve data directly from the index** itself. This leads us to the concept of **covering indexes**.

---

### ✅ What is a Covering Index?

A **covering index** is an index that includes **all the columns** required to satisfy a query. That means **MySQL doesn't need to read the full row** from the table (i.e., it skips the table lookup). Instead, it finds everything it needs in the index leaf pages.

This is different from a normal index, which:
- Is used to **locate rows quickly** via filtering/searching.
- Still requires MySQL to **go to the table** to retrieve additional column values that are **not in the index**.

---

### 📂 Index Structure: Normal vs. Covering Index

![ ✔ covering index vs common index](/sections/5-covering-index/imgs/1.jpg)


**🔹 Normal Index:**
- Only contains the indexed column(s) and a pointer to the row (via the primary key).
- Any additional columns must be retrieved through a **secondary lookup**.
  
**🔹 Covering Index:**
- Contains all the **columns needed by the query** (used in `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`, etc.).
- Query is resolved **entirely using the index** — no table lookup required.
  
**🔍 Visual Concept:**
```
Covering Index = [ColumnA, ColumnB, ColumnC]  ⬅ All required columns here
Query: SELECT ColumnA, ColumnC WHERE ColumnB = ?
```

![ ✔ covering index exclude large parts of the rows](/sections/5-covering-index/imgs/2.jpg)

> [!NOTE]
> Covering index can exclude the large parts of the row especially if you have `BLOB` or `CLOB` data type 

---

### 💡 Example: City Table in the World Sample DB

Let's say we want to run this query:

```sql
 select name, district from city where CountryCode = 'USA';
```

MySQL will **use the index on `CountryCode`** to find matching rows, but still needs to **go to the table** to get `name` and `district`.

---

### 🛠️ Optimization: Create a Covering Index

We can **add an index** that covers all needed columns:
```sql
 alter table city add index country_district_name_idx (CountryCode, District, Name);
 ```

This index includes all columns required for the query, so **MySQL can resolve the query using just the index** — no extra I/O.

**If you run:**
```sql
 explain analyze select name, district from city where CountryCode = 'USA';
```

You'll likely see the query plan show **"Using index"**, which confirms the **covering index is used**.

---

### 🧠 Choosing Column Order in Index

When building a covering index:
- The **first column** should match the most common filtering condition (`WHERE` clause).
- Subsequent columns should:
  - Be frequently queried together
  - Appear in `ORDER BY`, `GROUP BY`, or `SELECT`
- If multiple columns are used equally, **put the more selective column earlier** to reduce scanned rows.

In our case:
- `CountryCode` is first (used in WHERE)
- `Name` is more selective than `District`, so it comes next

```sql
 alter table city add index country_district_name_idx (CountryCode, Name, District);
```

---

### 🧪 Cleanup: Replace Old Index

If the new index makes the old one redundant (e.g., index on just `CountryCode`), we can make the old index invisible:

```sql
 alter table city alter index CountryCode invisible;
```
This lets us **test query performance** without the old index before deciding to drop it.

---

### ✅ Summary

- A **covering index** contains all columns needed by a query.
- It avoids accessing the table, improving performance.
- **Choose column order** in the index carefully based on filtering and selectivity.
- **Make old indexes invisible** before dropping them when replacing with new ones.
