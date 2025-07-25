# 🔍 Example 3: Filtering on a Composite Primary Key (Partial Match)

In this example, we explore how MySQL handles filtering on a table with a **composite primary key**, using only **part of the key**.

---

### 🧪 Table Used: `countrylanguage`

- **Primary Key**: `(CountryCode, Language)`
- That means both columns together uniquely identify a row
- However, we're only filtering by `CountryCode`

```sql
SELECT * FROM countrylanguage WHERE CountryCode = 'CHN';
```
---

### 🔹 What's Happening

- MySQL can still **use the primary key index** even if we're only using the **first column** (`CountryCode`) of the composite key
- In the `EXPLAIN` output:
  - Access type = `ref` or `range`
  - Key used = `PRIMARY`
  - Key columns used = `CountryCode`

> 📌 Only the **left-most column(s)** of a composite index can be used for filtering ,other wise you need to create another index on the non left column or you will end up with full table scan

---

### ✅ Why This Is Efficient

- Because `CountryCode` is the **first column** in the composite key, MySQL can still navigate the B-Tree index efficiently
- This avoids a full table scan and improves performance
- This is a classic case of **partial index usage**

---

### ⚠️ Limitation

- If you try to filter by `Language` **alone**, MySQL **cannot use the primary key index**
- Index usage **only works left-to-right** in composite keys

---

### 📌 Summary

| Field | Value |
|-------|-------|
| **Query** | ` SELECT * FROM countrylanguage WHERE CountryCode = 'CHN';` |
| **Index Used** | ✅ Primary Key `(CountryCode, Language)` |
| **Access Type** | `ref` or `range` |
| **Estimated Rows** | Based on country population/language count |
| **Execution Speed** | ⚡ Fast (index used efficiently) |
| **Best Practice** | Always structure your filters to match the **left-most part** of composite indexes |
