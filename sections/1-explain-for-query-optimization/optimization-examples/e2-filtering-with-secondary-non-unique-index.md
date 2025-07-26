# 🔍 Example 2: Filtering with a Secondary Non-Unique Index (Single table - index access)

In this example, we optimize the query by filtering on a column that **has a secondary index** — improving performance compared to a full table scan.

### 🧪 Query:
```sql
SELECT * FROM city WHERE CountryCode = 'FRA';
```

- The `CountryCode` column has a secondary (non-unique) index
- MySQL can now use the index to locate matching rows faster


## 🔹 What Changed from Example 1?

| Concept        | Example 1 (`name`)      | Example 2 (`CountryCode`) |
| -------------- | ----------------------- | ------------------------- |
| Indexed?       | ❌ No index              | ✅ Indexed                 |
| Access Type    | `ALL` (full table scan) | `ref` (index lookup)      |
| Estimated Rows | \~4046 rows scanned     | \~40 rows accessed        |
| Performance    | High cost (slow)        | Lower cost (faster)       |


---

## 📈 How It Works
- MySQL uses the index on CountryCode to find relevant rows
- This is much cheaper than scanning the entire table
- The access type in the EXPLAIN output will now be ref, not ALL
- MySQL estimates 40 rows will be returned


&nbsp;

## 🔢 Why the Estimation Is Accurate
> "It's estimated that 40 rows will be accessed… exactly as InnoDB responds when asked how many rows will match."

- Because `CountryCode` is **indexed**, MySQL has **statistics** about its values
- It knows roughly how many rows match `'FRA'` thanks to the **index histogram** or cardinality info


&nbsp;

## ✅ Takeaway
> Using a column with a non-unique index can significantly reduce query cost.

- This is a common optimization: filtering using indexed columns
- Even if the index is not unique, it still allows efficient lookup
- In large tables, this change can make a query go from seconds to milliseconds

&nbsp;

## 📌 Summary

| Field               | Value                                           |
| ------------------- | ----------------------------------------------- |
| **Query**           | `SELECT * FROM city WHERE CountryCode = 'FRA';` |
| **Index Used**      | ✅ Secondary Index on `CountryCode`              |
| **Access Type**     | `ref`                                           |
| **Estimated Rows**  | `40`                                            |
| **Execution Speed** | ⚡ Fast                                          |
