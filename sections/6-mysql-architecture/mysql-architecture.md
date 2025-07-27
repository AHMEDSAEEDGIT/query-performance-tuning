## 🧠 Understanding MySQL Architecture and Query Execution

MySQL is very different from other database servers, and its architectural characteristics make it useful for a wide range of purposes. Although it's not perfect, it is flexible enough to work well in very demanding environments. Examples include:

- Web applications
- Data warehouses
- Content indexing
- Highly available and redundant systems
- Online transaction processing (OLTP)
- And much more.

### Storage Engine Architecture

One of MySQL’s most important and unusual features is its **storage engine architecture**. This design separates the **query processing** and other **server tasks** from **data storage and retrieval**.

> 📌 This flexibility allows developers to choose the most appropriate storage engine for their needs (e.g., InnoDB for transactions, MyISAM for read-heavy workloads).

To get high performance from MySQL, it’s essential to understand **how MySQL optimizes and executes queries**. Once you understand the internals, **query optimization** becomes a **logical, step-by-step process**, not a guessing game.

---

## Query Execution Flow

When we send a query to the server, MySQL follows this **step-by-step flow**:

![ ✔ query execution flow](/sections/6-mysql-architecture/imgs/3.jpg)


1. **Client sends SQL** statement to the server.
2. **Query Cache** (only in versions prior to MySQL 8): Checked for exact matches. *(Note: removed in MySQL 8+ for performance reasons.)*
3. **Parsing & Preprocessing**:
   - The SQL is parsed.
   - Syntax is checked.
   - A **parse tree** is built.
4. **Authorization**:
   - Checks whether the client has permission to run the query.
5. **Query Optimizer**:
   - Transforms the parse tree into a **query execution plan**.
   - Chooses indexes, join types, and access paths.
6. **Query Executor**:
   - Passes the plan to the **Storage Engine API**.
   - Retrieves rows, applies filters, and returns the result.
7. **Result Returned** to the client.

---

## MySQL Server Architecture Layers

MySQL Server can be conceptually divided into **three main layers**:

### 1. Connection Layer (Utility layer)
This includes services that are **not unique to MySQL**, such as:

![ ✔ Secondary index](/sections/6-mysql-architecture/imgs/4.jpg)


- Connection handling
- Authentication
- Security
- Thread management

These services are common in most **client-server architectures**.

> 💡 This is where the **client-server protocol** comes into play. It’s fast and simple but has a key limitation:
>
> - **No flow control**: Once a message is sent, the other side must receive the **entire** message before responding.

&nbsp;


---
## 💡 Understanding MySQL's Client-Server Protocol Limitation

MySQL uses a **simple and fast client-server communication protocol**. This is great for performance, but it introduces a limitation you should be aware of:

> ❗ **No Flow Control**  
> Once one side (client or server) sends a message, the other side **must receive the entire message** before it can respond.

#### What does "no flow control" mean?

- In more advanced communication protocols (like TCP with flow control), data can be **paused**, **chunked**, or processed **incrementally**, depending on how much has been received.
- In MySQL's protocol, however, **you cannot start acting on part of the message while the rest is still being sent**.

#### Why does this matter?

1. **Server Response:**
   - When the server sends query results to the client, it sends the **entire result set**.
   - The client **must receive the whole result set** before doing anything else (like sending a new query).
   - If the result set is **large**, this can lead to:
     - Memory pressure on the client
     - Delays before the client can continue
     - Locked resources on the server

2. **Client Requests:**
   - When a client sends a large request (e.g., bulk insert), the server **must receive the full request** before parsing or executing it.

#### Practical Example:

Let’s say you run a query that returns 1 million rows:

> `SELECT * FROM big_table;`

- The server begins streaming the rows to the client.
- **The client must fully receive** all the rows before:
  - Sending another command
  - Processing or canceling the query
- Meanwhile, **the server keeps locks, file handles, and memory buffers open**, waiting for the client to finish.


--- 
## Why `LIMIT` is Important

Because of the no-flow-control protocol, the server will return the **entire result set**, and the client has to fetch all of it before proceeding. This is why using the `LIMIT` clause is crucial:

> It prevents the server from returning excessive rows that you may not need.

&nbsp;

## Memory Use in Clients

When using MySQL client libraries (e.g., via Python, Java, PHP):

- The **default behavior** is to **buffer** the entire result set **in memory**.
- This means:
  - **Faster results** once fetched
  - **Less load** on the server after the buffer is filled
  - But **higher memory usage** on the client side

> ⚠️ Until all rows are fetched, **MySQL won't release locks or resources** associated with the query. This can lead to performance issues if the client is slow.

---

## Buffered vs Unbuffered Fetching

There are two ways to handle result sets:

### Buffered (default)
- Fetches **all rows** at once.
- Minimizes round trips between client and server.
- Uses **more memory** but **frees server resources quickly**.

### Unbuffered (manual)
- Fetches **rows one at a time**.
- **Saves memory**.
- But **locks and resources stay open** on the server until the fetch loop is complete.

> Best for **large datasets** that can’t fit in memory.
---

## 🧠 How MySQL Executes a Query

To begin, let's consider a simple query.

![ ✔ Parser and preprocessor](/sections/6-mysql-architecture/imgs/6.jpg)


After the connection is handled, **MySQL Parser** breaks the query into **tokens** and builds a **parse tree** from them.

The parser uses SQL grammar to:
- Interpret and validate the query
- Detect errors like unterminated strings
- Check that columns and tables exist

Next, the **preprocessor** checks **user privileges** to ensure that the requesting client has the rights to run the query.

> 🔸 This step is normally fast, unless the server has a very large number of privileges to check.

---

## 🔧 The Brain of MySQL (Second Layer)

Much of MySQL’s core logic lives here, including:

- **Query analysis**
- **Optimization**
- **Built-in functions** (date, math, encryption, etc.)

> ✅ Any cross-storage-engine logic exists at this layer.

&nbsp;

### 🔁 Query Rewrite

Before optimization, the **Rewrite Component** may rewrite the query based on internal rules.  
For example:

> If a query is executed on a view, MySQL rewrites it to access the **underlying base tables** instead.

At this point, the parse tree is now **valid** and ready for the **optimizer**.

---

## 🔍 Query Optimization

MySQL tries to **optimize the execution plan** by:

- Exploring multiple valid paths to execute a query
- Choosing the **least costly** plan

![ ✔ Parser and preprocessor](/sections/6-mysql-architecture/imgs/7.jpg)


> The optimizer uses **statistics** like:
> - Pages per table or index
> - Index cardinality (distinct values)
> - Row and key lengths
> - Key distribution

&nbsp;

### ⚠️ Why Optimizer Might Fail

Despite being smart, the optimizer can make mistakes:

- **Inaccurate statistics** from storage engines like InnoDB, due to MVCC
- **Uncertainty** about which pages are in memory or on disk (I/O impact is unclear)
- **Estimated cost ≠ real cost** (it's just a rough approximation)
- **Incomplete plan evaluation** (it can't test every option)

---

## ✅ Built-in Optimizations

MySQL applies many internal optimizations, including:

- Reordering joins
- Converting joins
- Algebraic equivalence rules
- Optimizations for:
  - `COUNT()`
  - `MIN()` and `MAX()`
  - Subqueries

&nbsp;

### 🧠 When You Know Better Than the Optimizer

Sometimes **you know more than the optimizer** (e.g., data distribution, workload patterns).  
In such cases, you can:

- ✏️ **Rewrite the query**
- 💡 **Use optimizer hints**
- 🗃️ **Redesign your schema**
- 📌 **Add indexes**

---

## 🔍 MySQL Query Execution: Execution Plan & Storage Engines

The output after the **parsing** and **optimization** stages in MySQL is a **Query Execution Plan**. This plan describes exactly **how** MySQL will execute the query.

### 🛠 Execution Stage

![ ✔ Execution Stage](/sections/6-mysql-architecture/imgs/8.jpg)


Once the plan is created, it is passed to the **Query Execution Engine**, which is responsible for actually carrying out the instructions. Unlike the optimization stage (which is complex and cost-based), the execution stage is usually straightforward:

- MySQL simply **follows the instructions** in the plan step by step.
- Many of these operations call methods from the **Storage Engine Interface**, also known as the **Handler API**.

#### 📤 Final Step: Replying to the Client

After executing the plan:
- MySQL **sends a response to the client**.
- Even for queries that **don’t return data**, a response is still sent (e.g., number of rows affected).

#### 🏗️ MySQL's Layered Architecture

MySQL’s architecture is **layered**, with the **Query Execution Engine** at the top and **Storage Engines** underneath.

### 🗃️ Storage Engines
![ ✔ Execution Stage](/sections/6-mysql-architecture/imgs/9.jpg)

- The **third layer** of MySQL is made up of **Storage Engines** — responsible for reading/writing data to disk.
- Storage engines are **pluggable**, meaning they can be added or replaced easily based on needs.

The main storage engine used in most applications is:

> **InnoDB**

- ✅ Fully **ACID-compliant** (supports **transactions**)
- ✅ Designed for **high concurrency** workloads
- ✅ Great for handling **many short-lived transactions**
- ✅ Balances **reliability** and **performance**
- ✅ Supports **row-level locking**, **foreign keys**, and **crash recovery**

There are other engines like:

> **NDB Cluster** – Also transactional, optimized for **MySQL Cluster** setups.

However, unless you have a **very specific use case**, **InnoDB** is the default and most broadly useful engine.

#### 📚 Recommendation

If you want to learn about storage engines:
- **Focus deeply on InnoDB** rather than studying all engines equally.
- Understanding InnoDB will give you insight into real-world MySQL performance.

#### ⚙️ How the Storage Engine Affects Optimization




While the **optimizer** doesn't directly care which engine is used:
- It **consults the storage engine** to gather **statistics** (like row count, index cardinality).
- It asks about the **cost** of various operations (e.g., index scan vs full scan).
- This feedback affects the **query plan** that the optimizer generates.

#### 🧪 Key Takeaways

- The **Optimizer** decides **what to do**.
- The **Execution Engine** simply **does it**.
- The **Storage Engine** provides the actual **data access** logic and plays a major role in performance.
- MySQL's execution process involves **parsing → optimizing → executing → returning results**.

💡 **Optimization and execution are the most critical parts** to understand in query tuning.

