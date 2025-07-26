### 🔧 Setup

First, we'll drop any existing composite index:

```sql
 DROP INDEX name_state_idx ON userinfo;
```

**Then, define two benchmark queries:**
**Q1** – simple count by `state_id`:
```sql
 SELECT COUNT(*) FROM userinfo WHERE state_id = 5;
```

**Q2** – fetch columns by `state_id`:
```sql
 SELECT state_id, city, address FROM userinfo WHERE state_id = 100;
```
---

## ⚙️ Benchmark Scenarios

We benchmark under 3 conditions:

1. ✅ **Single-column index only** on `state_id`  
2. ✅ **Composite index only** on `(state_id, city, address)`  
3. ✅ **Both indexes present**

We'll execute each query **300 times** in Python and calculate **queries per second** (QPS). Tests have already been performed and summarized.

---

## 📊 Observations

- **Q1** (count) performs slightly better with **only** the single-column index.
- **Q2** (select multiple columns) is **much faster** with the **composite index**, because it's **covering** and avoids a table lookup.


### ✅ Best Performance for Both?

![.](/sections/2-composite-index-best-practices/imgs/1.jpg)
Keep **both** indexes — even if one is redundant — to optimize both Q1 and Q2.

---

## ⚠️ Insertion Performance

Having multiple indexes increases **write overhead**.

This table illustrates the cost of inserting 30,000 rows:

![.](/sections/2-composite-index-best-practices/imgs/2.jpg)


| Indexes Present                  | Insert Time   |
|----------------------------------|---------------|
| No indexes                       | Fastest       |
| Single index                     | Slower        |
| Composite index                  | Slower        |
| Both indexes (redundant)        | Slowest       |

> [!NOTE]
> More indexes = more maintenance cost (especially `INSERT`, `UPDATE`, `DELETE`)  
> This worsens as table size increases or memory is limited.


---
## 💡 Scripts Used

```sql
 USE world;  
 SHOW INDEXES FROM userinfo;  
```
**Prepration before doing the benchmark.**
```sql 
 DROP INDEX name_state_idx ON userinfo; -- redundant index remove it if exists
```
**Q1**  
```sql
SELECT COUNT(*) FROM userinfo WHERE state_id = 5;  
```

**Q2** 
```sql
 SELECT state_id, city, address FROM userinfo WHERE state_id = 100;
```

**Create single-column index**  
```sql
 CREATE INDEX idx_state_id ON userinfo(state_id);  
```

```sql
 EXPLAIN SELECT COUNT(*) FROM userinfo WHERE state_id = 5;  
 EXPLAIN SELECT state_id, city, address FROM userinfo WHERE state_id = 100;
```

**To limit test the time**
```sql
 SET PROFILING = 1;  
 SELECT COUNT(*) FROM userinfo WHERE state_id = 5;  
 SHOW PROFILES;
```

**Drop and create composite index**
```sql
 DROP INDEX idx_state_id ON userinfo;  
 DROP INDEX idx_state_city_address ON userinfo;  
 CREATE INDEX idx_state_city_address ON userinfo(state_id, city, address);
```

```sql
 EXPLAIN SELECT COUNT(*) FROM userinfo WHERE state_id = 5;  
 EXPLAIN SELECT state_id, city, address FROM userinfo WHERE state_id = 100;
```

**Add single index again**
```sql
 CREATE INDEX idx_state_id ON userinfo(state_id);  
```
```sql
 EXPLAIN SELECT COUNT(*) FROM userinfo WHERE state_id = 5;  
 EXPLAIN SELECT state_id, city, address FROM userinfo WHERE state_id = 100;
```
**Check for redundant indexes**
```sql
 SELECT * FROM sys.schema_redundant_indexes;
```