# 🛒 E-commerce Sales Analytics

## 📌 About the Project
A complete end-to-end SQL project built using **MySQL Workbench**.  
Simulates a real e-commerce business and answers key business  
questions using pure SQL — no Python, no Excel.

## 🗂 Database Name
`ecommerce_analytics`

## 📋 Schema — 4 Tables
| Table | Description |
|---|---|
| `customers` | Customer details — name, city, segment |
| `products` | Product catalogue — category, price, stock |
| `orders` | Each order — date, status, payment mode |
| `order_items` | Line items per order — quantity, discount |

## 💡 Business Questions Answered
- Which product category generates the most revenue?
- Who are the top 5 customers by total spend?
- What is the return rate by category?
- Are customers one-time or returning buyers?
- Which payment mode does each segment prefer?
- What is the running revenue total month over month?

## 🛠 SQL Concepts Used
| Concept | Purpose |
|---|---|
| INNER JOIN / LEFT JOIN | Combining tables |
| GROUP BY + Aggregates | Revenue & order totals |
| CASE WHEN | Customer segmentation |
| CTEs (WITH clause) | Multi-step business logic |
| RANK() / DENSE_RANK() | Product & customer ranking |
| Running Totals | Month-over-month growth |
| LEFT JOIN Anti-pattern | Finding unordered products |

## 📁 File
| File | Description |
|---|---|
| `ecommerce-sales-analytics.sql` | Complete project — schema, data & all analysis queries |

## ▶ How to Run
1. Open **MySQL Workbench**
2. Open the file `ecommerce-sales-analytics.sql`
3. Run the full script top to bottom
4. All tables, data and query results will be generated
