# 🛠️ MySQL Query Optimization & Indexing Guide

Welcome to this comprehensive guide and hands-on reference for **MySQL query optimization**, **indexing strategies**, and **performance tuning**. This repository is structured to help developers, DBAs, and learners understand not just the *how*, but the *why* behind optimization decisions.

Whether you're debugging slow queries, trying to understand how `EXPLAIN` works, or learning about composite indexes and lock contention—this repo offers structured learning material and real examples to follow.

---

## ✨ What's Inside?

This repository contains curated content and real-world query examples based on:

- **Query performance analysis using `EXPLAIN` and `EXPLAIN ANALYZE`**
- **Indexing best practices**: composite indexes, covering indexes, redundant indexes, and more
- **Choosing optimal primary keys** and how it affects data access patterns
- **MySQL's internal architecture**: how MySQL handles query parsing, optimization, execution, and locking
- **Benchmark experiments** with real SQL samples
- Insights from **Performance Schema**, lock contention, deadlocks, and error analysis

Each section is written with practical use cases and markdown-friendly formatting so it’s easy to navigate and reference.

---

## 🎯 Who Should Use This Repo?

- Backend developers trying to optimize their SQL queries
- DBAs and data engineers looking to tune performance in production systems
- Students and learners preparing for database interviews or certifications
- Anyone wanting to better understand how MySQL works under the hood

---

## 📚 Table of Contents

- [1. Explain statement for query optimization](/sections/1-explain-for-query-optimization/explain-for-query-optimization.md)
    - [1.1 Filtering on a Non-Indexed Column](/sections/1-explain-for-query-optimization/optimization-examples/e1-filtering-non-Indexed-column.md)
    - [1.2 Filtering with a Secondary Non-Unique Index](/sections/1-explain-for-query-optimization/optimization-examples/e2-filtering-with-secondary-non-unique-index.md)
    - [1.3 Filtering on a Composite Primary Key (Partial Match)](/sections/1-explain-for-query-optimization/optimization-examples/e3-composite-index.md)
    - [1.4 Top 5 Cities population in the Smallest European Countries](/sections/1-explain-for-query-optimization/optimization-examples/e4-combining-joins-sorting-filtering.md)
    - [1.5 Understanding Query Estimates and EXPLAIN ANALYZE in MySQL](/sections/1-explain-for-query-optimization/optimization-examples/make-sense-of-explain-analyze.md)

- [2. Composite index best practices](/sections/2-composite-index-best-practices/composite-index-best-practices.md)
    - [2.1 Different indeces effect](/sections/2-composite-index-best-practices/benchmark/index-effect-examples.md)
    - [2.2 Redundant indexes benchmark](/sections/2-composite-index-best-practices/benchmark/redundant-indeces.md)

- [3. How to choose primary key](/sections/3-how-to-choose-primary-key/how-to-choose-primary-key.md)

- [4. Index Performance](/sections/4-index-performance/index-performance.md)

- [5. Covering Index](/sections/5-covering-index/covering-index.md)

- [6. MySQL Architecture](/sections/6-mysql-architecture/mysql-architecture.md)

- [7. Spotting performance problems](/sections/7-spotting-performance-problems/spotting-performance-problems.md)

---

## 🔍 Features and Highlights

- ✅ **Fenced markdown format** — optimized for readability and copy-paste into technical blogs or documentation
- ✅ Real-world **MySQL queries and explain plans**
- ✅ Commentary on **index design**, **query patterns**, **access strategies**, and **optimizer behavior**
- ✅ Simplified explanations of **lock contention**, **deadlocks**, and how **errors** affect performance
- ✅ **Performance Schema** usage to diagnose problems

---

## 📖 References & Learning Sources

- [MySQL Official Documentation](https://dev.mysql.com/doc/)
- YouTube playlist used as source material (https://www.youtube.com/@HighPerformanceProgramming)
- Real-world queries tested in MySQL 8.x environment

---

## 🗂️ Directory Structure

```
sections/
├── 1-explain-for-query-optimization/
│   └── optimization-examples/
├── 2-composite-index-best-practices/
│   └── benchmark/
├── 3-how-to-choose-primary-key/
├── 4-index-performance/
├── 5-covering-index/
├── 6-mysql-architecture/
└── 7-mysql-architecture/spotting-performance-problems/
```

---

## 💬 Feedback

If you find something confusing, incorrect, or worth expanding, feel free to [open an issue](https://github.com/your-username/your-repo-name/issues) or start a discussion. Contributions and feedback are welcome!

