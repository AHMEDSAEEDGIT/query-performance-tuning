## 🔍 Example 4: Top 5 Cities population in the Smallest European Countries

This example explores how the **MySQL Optimizer** handles:
- Subqueries
- Nested loop joins
- Sorting and limiting
- Streaming results
- Index usage

---

### 🧪 Goal

We want to:
1. **Find the 10 smallest countries** in Europe (by surface area)
2. **Get the top 5 most populated cities** from these countries

---

### 🔹 The Query

```sql
 SELECT ci.ID, ci.Name, ci.District,  
        co.Name AS Country, ci.Population  
 FROM world.city ci  
 INNER JOIN (  
     SELECT Code, Name  
     FROM world.country  
     WHERE Continent = 'Europe'  
     ORDER BY SurfaceArea  
     LIMIT 10  
 ) co ON co.Code = ci.CountryCode  
 ORDER BY ci.Population DESC  
 LIMIT 5;
```
---

### 🧠 Step-by-Step Explanation

#### 1. 🧩 Subquery (Derived Table)

The subquery:

> SELECT Code, Name  
> FROM world.country  
> WHERE Continent = 'Europe'  
> ORDER BY SurfaceArea  
> LIMIT 10

- Filters only European countries
- Sorts them by `SurfaceArea` in ascending order
- Limits the result to the **10 smallest** ones
- This becomes a **materialized derived table** stored temporarily in memory

✅ Efficient because it narrows the join scope to just 10 countries

---

#### 2. 🔗 Join with `city` Table

> INNER JOIN ... ON co.Code = ci.CountryCode

- MySQL joins each of the 10 countries with the `city` table using `CountryCode`
- This is done with a **Nested Loop Join**:
  - For each of the 10 countries, MySQL does an **index lookup** in the `city` table to find matching cities

🔁 If 2 cities per country are found → approx. 20 rows returned from the join

---

#### 3. 🔢 Sorting and Limiting the Final Output

> ORDER BY ci.Population DESC  
> LIMIT 5\G;

- Sorts the cities **by population (descending)**
- Returns only the **top 5 most populated cities** from the joined result
- The `\G` syntax is for **vertical format output** in MySQL CLI (better readability)

💡 Since the final LIMIT is 5, MySQL doesn’t need to materialize all join rows — it can **stream** them and stop after 5

---

### ⚙️ Execution Plan Highlights

| Feature               | Details                                                                 |
|-----------------------|-------------------------------------------------------------------------|
| Subquery              | Materialized derived table (`LIMIT 10`)                                 |
| Join Type             | Nested loop join (10 iterations)                                        |
| Join Method           | Index lookup via `ci.CountryCode`                                       |
| Estimated Join Rows   | ~174 rows (10 countries × avg 17.4 cities)                              |
| Actual Join Rows      | ~20 rows (based on real data in small countries)                        |
| Result Limiting       | Output is sorted and streamed, not materialized                         |
| Estimated Query Cost  | ~4ms (quick due to indexing and limits)                                 |

---










### 🔍 EXPLAIN ANALYZE Breakdown: Top 5 Most Populated Cities in Small European Countries

This execution plan shows how MySQL processes a query that retrieves the **5 most populated cities** in the **10 smallest countries** in **Europe**.
**💡How to read it** : follow the order before the arrow for each line 

---

#### 🗂️ Execution Tree (Indented View)

> 11  -> Limit: 5 row(s)  (actual time=0.366..0.367 rows=5 loops=1)  
> 10   -> Sort: ci.Population DESC, limit input to 5 row(s) per chunk  (actual time=0.366..0.366 rows=5 loops=1)  
> 9     -> Stream results  (cost=90.3 rows=174) (actual time=0.256..0.351 rows=15 loops=1)  
> 7      -> Nested loop inner join  (cost=90.3 rows=174) (actual time=0.255..0.346 rows=15 loops=1)  
> 6       -> Table scan on `co`  (cost=26.9..29.3 rows=10) (actual time=0.229..0.231 rows=10 loops=1)  
> 5        -> Materialize  (cost=26.7..26.7 rows=10) (actual time=0.228..0.228 rows=10 loops=1)  
> 4         -> Limit: 10 row(s)  (cost=25.7 rows=10) (actual time=0.211..0.213 rows=10 loops=1)  
> 3          -> Sort: country.SurfaceArea, limit input to 10 row(s) per chunk  (cost=25.7 rows=239) (actual time=0.211..0.212 rows=10 loops=1)  
> 2           -> Filter: (country.Continent = 'Europe')  (cost=25.7 rows=239) (actual time=0.0519..0.182 rows=46 loops=1)  
> 1            -> Table scan on `country`  (cost=25.7 rows=239) (actual time=0.0467..0.155 rows=239 loops=1)  
> 8       -> Index lookup on `ci` using CountryCode (CountryCode=co.Code)  (cost=4.53 rows=17.4) (actual time=0.0102..0.0111 rows=1.5 loops=10)  

---

#### 📝 Step-by-Step Explanation

| Step | Description |
|------|-------------|
| **Limit: 5** | Final output returns **5 rows** — stops processing after 5 top cities are found. |
| **Sort: `ci.Population DESC`** | Sorts the result set of cities by population in descending order. Only the **top 5** cities are kept. |
| **Stream Results** | MySQL streams intermediate results instead of fully materializing them, saving memory. |
| **Nested Loop Join** | Joins the 10 smallest countries (aliased as `co`) with their cities (aliased as `ci`). For each country, it finds matching cities. |
| **Table Scan on `co`** | A scan on the derived table of the 10 smallest countries. |
| **Materialize** | Materializes the result of the 10-country selection in memory for reuse in the join. |
| **Limit 10** | Limits the number of countries to 10 (the smallest ones). |
| **Sort by SurfaceArea** | Sorts countries by `SurfaceArea` ascending. |
| **Filter: Continent = 'Europe'** | Applies a filter to only keep countries from Europe. |
| **Table Scan on `country`** | Scans the full `country` table (239 rows) to apply the filter and sort. |
| **Index Lookup on `ci`** | For each country, finds its cities using an **index on `CountryCode`** in the `city` table. Efficient join. |

---

#### 📈 Performance Observations

- ✅ **Efficient use of index** for joining `city.CountryCode` = `country.Code`
- ✅ **Materialization** helps avoid re-computing the same result set during nested loops
- ✅ **Streaming results** optimizes memory
- ✅ **Short-circuit sorting and limit** reduces the amount of sorting MySQL has to perform
- ⚠️ Full table scan on `country` is expected, but efficient due to the small number of rows

---

#### 🧠 Key Takeaways

- **EXPLAIN ANALYZE** provides actual execution times, row counts, and cost estimates.
- You can identify which part of the plan consumes time or does heavy lifting.
- Index lookups and limit + sort strategies are well-used by MySQL here.

---


> [!TIP]
> Look for full table scans (often performance bottlenecks)
> Check if indexes are being used (index lookup is good, table scan is often bad)
> Watch for sorting operations (can be expensive for large datasets)
> Note temporary tables/materialization (sometimes unavoidable but can be optimized)
> Compare rows processed vs rows returned (large discrepancies may indicate issues)
