# 🗃️ Choosing the Right Primary Key and Understanding Indexes in MySQL

## 🔍 Everything in MySQL is an Index

- **InnoDB**, MySQL’s main storage engine, uses an **index-organized table** structure.
- Data in tables is physically organized using an index — specifically, a **clustered index** based on the **primary key**.

## 📌 Why Choosing the Right Primary Key Matters

- The **primary key** affects:
  - **Random vs sequential I/O**
  - **Size of secondary indexes**
  - **Number of pages** read into the buffer pool
- In InnoDB, the **primary key is always a B-Tree index**.

## ✅ Characteristics of an Optimal Primary Key



### 1. 🔹 Small in Size

- **Why?**
  - In InnoDB, every **secondary index** includes the **primary key value** as part of its internal structure.
  - A large primary key (e.g., a long string or composite key with many columns) increases the **storage size** of all indexes.
- **Impact:**
  - More disk space used.
  - More memory consumed in buffer pool.
  - Slower performance during reads/writes and index scans.
- **Tip:** Prefer short `INT`, `BIGINT`, or short `CHAR(n)` over large `VARCHAR` or long composite keys.

### 2. 📈 Monotonically Increasing

- **What it means:** The primary key values should increase in a steady, ordered way — e.g., `1, 2, 3...` instead of jumping randomly.
- **Why?**
  - MySQL appends new rows to the **end of the index** if keys are increasing.
  - This reduces the need to **split index pages** or insert rows in the middle of existing pages.
- **Impact:**
  - Faster inserts.
  - Less fragmentation.
  - More efficient use of the **buffer pool**.
- **Tip:** Auto-increment IDs (`INT AUTO_INCREMENT`) are a good example of monotonically increasing values.

### 3. 🧩 Groups Frequently Queried Rows Close Together

- **What it means:** Choose a primary key that places related or commonly queried rows **physically near each other** in the clustered index.
- **Why?**
  - MySQL stores rows **physically ordered** by primary key in InnoDB.
  - When rows that are often queried together are stored close, fewer **disk/page reads** are needed.
- **Impact:**
  - Better **cache locality**.
  - Reduced I/O during range scans.
  - Faster query performance for group-based access patterns.
- **Example:**
  - If you're often querying orders by `user_id`, it might make sense to **cluster** rows using `user_id` as part of the key (e.g., `(user_id, order_id)`).

---


## 🌿 Understanding Clustered Index in InnoDB

![ ✔ Clustered index on a primary key](/sections/3-how-to-choose-primary-key/imgs/1.jpg)

> InnoDB uses the primary key for the clustered index by default.

- **Leaf nodes** in the clustered index store **full rows**.
- **Inner nodes** store only the **indexed columns**.
- If no primary key is defined:
  - MySQL looks for a **unique, non-nullable** index to use.
  - If none exists, MySQL creates a **hidden primary key** for clustering.

## ⚠️ Performance Implications

- A clustering primary key can **boost performance** or cause **serious performance issues**.
- Especially important when **switching storage engines** (e.g., from InnoDB to another).

## 📚 Secondary Indexes and Double Lookups

![ ✔ Secondary index on another key](/sections/3-how-to-choose-primary-key/imgs/2.jpg)

> A **secondary index** is any index that is *not* the primary key.

### 🔁 Why Two Lookups?

1. MySQL uses the **secondary index** to locate the **primary key** of the row.
2. Then it uses the **primary key** to look up the **actual row** in the clustered index.

### 💡 Example Query

> SELECT username FROM user_info WHERE email = 'value';

- If `email` is a secondary index:
  - MySQL **first finds** the corresponding **primary key** via the `email` index.
  - Then it **retrieves the full row** using the primary key via the clustered index.

## 📦 Impact of Large Primary Keys

- Secondary indexes store the **primary key** with every indexed row.
- Therefore, **large primary keys increase**:
  - **Size of secondary indexes**
  - **Memory usage**
  - **Disk I/O**
---
## 🧱 How Clustered Indexes Improve Data Access in MySQL

In MySQL (with InnoDB), data is stored in **fixed-size pages**, typically **16KB**. Understanding how **clustered indexes** work can help optimize performance, especially for I/O-bound workloads.

### 📌 Why Store Data in Pages?

- Pages are blocks of memory or disk where rows are physically stored.
- **Reading a page is the basic I/O operation** — not individual rows.
- The goal is to **maximize the amount of useful data per I/O read**.
- When **related rows are clustered together**, the database can:
  - Fetch more relevant data with **fewer page reads**.
  - Reduce **random I/O**.
  - Increase **cache efficiency**.

### 🔗 Clustered Index = Data + Index Together

- In InnoDB, the **primary key is the clustered index**.
- This means the **actual row data is stored in the same B-Tree structure** as the primary key.
- Contrast this with non-clustered indexes, where:
  - The index stores pointers (row IDs) to fetch the row separately.
  - This adds an extra step and I/O hit.

---

### 📬 Example: Mailbox System

> Imagine you store user messages in a table. If the primary key includes `user_id`, then:
>
> - All of a user's messages are physically **stored next to each other**.
> - A query like `SELECT * FROM messages WHERE user_id = 1001` can be fulfilled by **reading just a few pages**.
> - Without clustering, each message might be scattered, requiring a separate disk I/O.

---

### ⚡ Benefits of Clustered Indexing

- ✅ Fast **primary key lookups**.
- ✅ Efficient **range scans** (e.g., `BETWEEN`, `ORDER BY`).
- ✅ Improved **join performance** when foreign keys follow clustering logic.
- ✅ Better performance for **frequently accessed data** grouped by primary key.

---

### ⚠️ Downsides & Pitfalls

#### 🔄 Page Splits
![ ✔ Page split](/sections/3-how-to-choose-primary-key/imgs/3.jpg)


> When inserting a new row, if the target page is already full:
>
> - MySQL must **split the page** into two.
> - This operation is costly and causes **fragmentation**.
> - More pages = more disk usage.

#### 🐌 Insert Speed Depends on Order

> Inserting rows **in primary key order** is the fastest:
>
> - Rows are appended to the end of the B-Tree.
> - Avoids page splits and fragmentation.
>
> If rows are inserted **out of order**, InnoDB might:
>
> - Constantly reorganize the tree.
> - Degrade performance over time.

#### 🧹 Table Optimization

> [!NOTE]
> After bulk inserts (especially out-of-order):
> - Run `OPTIMIZE TABLE your_table;`
> - This defragments pages and rebuilds the clustered index for better access.

---

### 🧠 Important Insight

> **Clustered indexing helps the most when your workload is I/O-bound.**
>
> - If all your data fits in memory (buffer pool), the physical layout matters less.
> - In-memory access is fast regardless of data order.

---

### ✅ Summary

| Property                     | Benefit                                                   |
|-----------------------------|------------------------------------------------------------|
| Rows stored in same page    | Fewer I/O reads for related data                           |
| Index and data together     | Fast lookups and fewer joins                              |
| Order matters               | Faster inserts and less fragmentation                     |
| Optimized for primary key   | Best for range queries, ordered scans, and batch access    |

```sql
-- After bulk insert (out-of-order), run this:
OPTIMIZE TABLE messages;
```

---
## 🧠 Understanding Clustered Indexes and Primary Key Choices in InnoDB

In InnoDB (the default storage engine in MySQL), the **primary key** is used as the **clustered index**. This means the data is physically stored in the order of the primary key. Choosing the right primary key can significantly impact performance — especially during **inserts**, **joins**, and **range queries**.

---

### ✅ Why Use an Auto-Increment Primary Key?

If you don’t have a natural primary key and **don’t need any specific clustering**, using a **surrogate key** (like an `AUTO_INCREMENT` integer) is a good strategy. Here's why:

![ ✔ Auto increment in the PK](/sections/3-how-to-choose-primary-key/imgs/4.jpg)


- **Small in size**: Integers (e.g., `INT`) are smaller (4 bytes) than strings like `UUID` (16+ bytes). This saves storage and improves cache efficiency.
- **Monotonically increasing**: Each new row gets a higher key than the last. This avoids random insertions and allows InnoDB to always insert at the end.
- **Groups frequently queried rows close together**: Sequential inserts mean rows are physically near each other. This helps range scans and improves locality of reference.


---

### ⚠️ Why UUIDs Can Hurt Performance

Using `UUID` as a primary key causes problems because values are:

- **Large in size**: 16 bytes vs. 4 bytes (INT).
- **Not sequential**: They appear in random order.
- **Cause page splits**: Since new rows can go anywhere in the index, InnoDB may need to split pages and shuffle rows around.

This leads to:

- **Higher write latency**
- **More random I/O**
- **Fragmented data**
- **Larger indexes**



---

### 🧪 Performance Comparison benchmark example

A test inserts **1 million rows** into two identical tables:

1. One with `AUTO_INCREMENT` integer key

```sql
-- Create the userinfo 
CREATE TABLE userinfo (
    id int unsigned NOT NULL AUTO_INCREMENT,
    name varchar(64) NOT NULL DEFAULT '',
    email varchar(64) NOT NULL DEFAULT '',
    password varchar(64) NOT NULL DEFAULT '',
    dob date DEFAULT NULL,
    address varchar(255) NOT NULL DEFAULT '',
    city varchar(64) NOT NULL DEFAULT '',
    state_id smallint unsigned NOT NULL DEFAULT '0',
    zip varchar(8) NOT NULL DEFAULT '',
    country_id smallint unsigned NOT NULL DEFAULT '0',
    account_type varchar(32) NOT NULL DEFAULT '',
    closest_airport varchar(3) NOT NULL DEFAULT '',
    PRIMARY KEY (id),
    UNIQUE KEY email (email)
) ;
```
2. One with `UUID` as primary key
```sql
-- Create the userinfo 
CREATE TABLE userinfo_uuid (
    id int uuid NOT NULL AUTO_INCREMENT,
    name varchar(64) NOT NULL DEFAULT '',
    email varchar(64) NOT NULL DEFAULT '',
    password varchar(64) NOT NULL DEFAULT '',
    dob date DEFAULT NULL,
    address varchar(255) NOT NULL DEFAULT '',
    city varchar(64) NOT NULL DEFAULT '',
    state_id smallint unsigned NOT NULL DEFAULT '0',
    zip varchar(8) NOT NULL DEFAULT '',
    country_id smallint unsigned NOT NULL DEFAULT '0',
    account_type varchar(32) NOT NULL DEFAULT '',
    closest_airport varchar(3) NOT NULL DEFAULT '',
    PRIMARY KEY (id),
    UNIQUE KEY email (email)
) ;
```

### on inserting records in the userinfo with autoincrement

![ ✔ inserting records in the userinfo](/sections/3-how-to-choose-primary-key/imgs/7.jpg)

### on inserting records in the userinfo_uuid with uuid

![ ✔ inserting records in the userinfo](/sections/3-how-to-choose-primary-key/imgs/8.jpg)
#### Result:

- Inserting into the UUID-based table took **210 seconds more**.
- The UUID-based table used **more disk space**.
- The UUID index became **more fragmented**.

---

### 📉 Why Does Random Insertion Hurt?

InnoDB fills pages **sequentially** when the primary key is increasing. When a page is full (**default 15/16 fill factor**), it moves to a new page.

With random keys (like UUIDs):

- InnoDB must **find the right page** and **split it** to insert.
- This causes:
  - **Page splits**
  - **Fragmentation**
  - **Cache misses**
  - **Random I/O**

> OPTIMIZE TABLE user_info_uuid;

```sql
 `OPTIMIZE TABLE` helps defragment and rebuild the table.
```
> [!TIP]
> - Use **sequential primary keys** (`AUTO_INCREMENT`) for best insert performance.
> - Avoid `UUID` as primary key unless necessary.
> - Consider keeping the UUID as a **secondary key** and using an `AUTO_INCREMENT` primary key if uniqueness across systems is required.

---
## ⚠️ The Drawbacks of Out-of-Order Inserts in InnoDB

When rows are inserted **out of order** in InnoDB (i.e., not following the primary key sequence), it results in a **sub-optimal data layout** with several performance implications:



### 🔁 Frequent Page Splits

- InnoDB stores rows physically in **primary key order**.
- When inserting rows with **random primary key values** (e.g., UUIDs), InnoDB can’t append rows at the end.
- It must find the correct page, which may be full.
- If the page is full, InnoDB **splits** the page to make space.

This involves:

- Moving data around.
- Creating new pages.
- Reducing page fill efficiency.

---

### 🧩 Fragmentation and Sparse Pages

Due to frequent page splitting:

- Pages become **irregularly filled**.
- The data layout becomes **fragmented**.
- Fragmentation reduces query performance, especially for **range scans** and **joins**.

---

### 💾 Cache Inefficiency and Random I/O

- Destination pages may not be in memory (buffer pool).
- If a page was **flushed to disk** or **never loaded**, InnoDB must:
  1. **Find the page location** on disk.
  2. **Read it from disk** into memory.
  3. **Insert the row**.

This causes **expensive random I/O**, which slows down insert performance drastically.

---

### 🛠️ Recommended Maintenance

If random values (like UUIDs) have already been inserted into a clustered index, consider running:

> OPTIMIZE TABLE your_table_name;

This will:

- Rebuild the table.
- Defragment pages.
- Optimize layout based on current key order.

---

### ✅ Best Practices

To maintain performance and minimize fragmentation:

- **Strive to insert rows in primary key order**.
- Use a **monotonically increasing key** (like `AUTO_INCREMENT`) as the clustered index.
- Ensure the primary key allows **sequential writes**.

---

### ⚖️ When You Can't Use Sequential Keys

If it's not possible to use a perfect primary key (e.g., for cross-system uniqueness):

- Make the **best compromise** between uniqueness and performance.
- In many workloads, an `AUTO_INCREMENT` `UNSIGNED INT` or `BIGINT` is sufficient.

> CREATE TABLE users (
>   id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
>   ...
> );

---

### 🤔 What About the Hidden Primary Key?

If you don't explicitly define a primary key, MySQL may create a **hidden clustered key**:

- This key is an **auto-incrementing 6-byte integer**.
- It is **only local to that MySQL instance**.
- It is **not visible** to the user or application.

#### 🚫 Drawbacks of the Hidden Key:

1. **Not usable in replication**:
   - Replicas can’t use it to identify which row to update.
   - It’s not consistent across servers.
2. **Global counter**:
   - All InnoDB tables share the same hidden counter.
   - Can become a **point of contention** under high insert load.
   - Impacts **concurrency and insert throughput**.

---

### 🧷 Final Advice

> Always explicitly define the primary key in your tables.

The primary key should be:

- **As small as possible** (to save space).
- **Monotonically increasing** (to avoid fragmentation).
- **Meaningful** if needed, but **surrogate keys** like `AUTO_INCREMENT` are usually better for performance.

> CREATE TABLE orders (
>   order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
>   user_id INT,
>   total DECIMAL(10, 2),
>   ...
> );



