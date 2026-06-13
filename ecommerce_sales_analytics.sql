CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

-- Customers
CREATE TABLE customers (
  customer_id  INT PRIMARY KEY,
  name         VARCHAR(60),
  city         VARCHAR(40),
  segment      VARCHAR(20),  -- 'Consumer','Corporate','SMB'
  join_date    DATE
);

-- Products
CREATE TABLE products (
  product_id   INT PRIMARY KEY,
  product_name VARCHAR(80),
  category     VARCHAR(30),
  price        DECIMAL(10,2),
  stock        INT
);

CREATE TABLE orders (
  order_id     INT PRIMARY KEY,
  customer_id  INT REFERENCES customers(customer_id),
  order_date   DATE,
  status       VARCHAR(20),  -- 'Delivered','Returned','Pending'
  payment_mode VARCHAR(20)   -- 'UPI','Card','COD','NetBanking'
);

-- Order line items
CREATE TABLE order_items (
  item_id    INT PRIMARY KEY,
  order_id   INT REFERENCES orders(order_id),
  product_id INT REFERENCES products(product_id),
  quantity   INT,
  discount   DECIMAL(4,2)  -- e.g. 0.10 = 10%
);



INSERT INTO customers VALUES
(1,'Aarav Shah','Mumbai','Consumer','2022-01-15'),
(2,'Priya Mehta','Delhi','Corporate','2022-03-20'),
(3,'Rohan Verma','Bangalore','SMB','2022-06-10'),
(4,'Sneha Gupta','Hyderabad','Consumer','2023-01-05'),
(5,'Vikram Nair','Chennai','Corporate','2023-04-18'),
(6,'Ananya Iyer','Pune','SMB','2023-07-22'),
(7,'Karan Joshi','Mumbai','Consumer','2023-09-01'),
(8,'Deepika Rao','Delhi','Corporate','2024-01-11');

INSERT INTO products VALUES
(1,'Laptop Pro 15','Electronics',75000.00,50),
(2,'Wireless Mouse','Electronics',1200.00,200),
(3,'Office Chair','Furniture',12500.00,30),
(4,'Notebook Set','Stationery',350.00,500),
(5,'Standing Desk','Furniture',22000.00,20),
(6,'USB-C Hub','Electronics',2800.00,150),
(7,'Mechanical Keyboard','Electronics',6500.00,80),
(8,'Whiteboard','Stationery',4200.00,60);

INSERT INTO orders VALUES
(101,1,'2024-01-10','Delivered','UPI'),
(102,2,'2024-01-18','Delivered','Card'),
(103,3,'2024-02-05','Returned','UPI'),
(104,4,'2024-02-20','Delivered','COD'),
(105,1,'2024-03-08','Delivered','UPI'),
(106,5,'2024-03-15','Pending','NetBanking'),
(107,6,'2024-04-01','Delivered','Card'),
(108,7,'2024-04-22','Delivered','UPI'),
(109,2,'2024-05-10','Returned','Card'),
(110,8,'2024-05-28','Delivered','UPI');

INSERT INTO order_items VALUES
(1,101,1,1,0.05),(2,101,2,2,0.00),
(3,102,3,2,0.10),(4,102,6,1,0.00),
(5,103,5,1,0.15),(6,104,4,5,0.00),
(7,104,8,1,0.05),(8,105,7,1,0.00),
(9,106,1,2,0.08),(10,107,2,3,0.00),
(11,107,3,1,0.10),(12,108,6,2,0.05),
(13,109,1,1,0.00),(14,110,7,2,0.10),
(15,110,4,10,0.00);

-- Q1 — total revenue by category
SELECT
  p.category,
  COUNT(DISTINCT o.order_id)                      AS total_orders,
  SUM(p.price * oi.quantity * (1 - oi.discount))  AS net_revenue
FROM order_items oi
JOIN products   p  ON oi.product_id = p.product_id
JOIN orders     o  ON oi.order_id   = o.order_id
WHERE o.status = 'Delivered'
GROUP BY p.category
ORDER BY net_revenue DESC;

-- Q2 — order status distribution
SELECT
  status,
  COUNT(*)                                        AS order_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- Q3 — top 5 customers by spend
SELECT
  c.name,
  c.segment,
  c.city,
  COUNT(DISTINCT o.order_id)                      AS orders_placed,
  ROUND(SUM(p.price * oi.quantity * (1 - oi.discount)),2) AS total_spend
FROM customers  c
JOIN orders     o  ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id   = oi.order_id
JOIN products   p  ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.name, c.segment, c.city
ORDER BY total_spend DESC
LIMIT 5;

 --  Q4 — rank products by revenue within each category
 SELECT
  p.category,
  p.product_name,
  ROUND(SUM(p.price * oi.quantity),2) AS revenue,
  RANK() OVER (
    PARTITION BY p.category
    ORDER BY SUM(p.price * oi.quantity) DESC
  ) AS rank_in_category
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category, p.product_id, p.product_name, p.price
ORDER BY p.category, rank_in_category;

-- Q5 — running revenue total over time
SELECT
  DATE_FORMAT(o.order_date, '%Y-%m')              AS month,
  ROUND(SUM(p.price * oi.quantity),2)           AS monthly_revenue,
  ROUND(SUM(SUM(p.price * oi.quantity)) OVER (
    ORDER BY DATE_FORMAT(o.order_date, '%Y-%m')
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ),2)                                             AS cumulative_revenue
FROM orders     o
JOIN order_items oi ON o.order_id   = oi.order_id
JOIN products   p  ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY month
ORDER BY month;

-- Q6 — identify repeat vs one-time buyers
WITH customer_order_counts AS (
  SELECT
    customer_id,
    COUNT(order_id) AS total_orders
  FROM orders
  GROUP BY customer_id
)
SELECT
  c.name,
  c.segment,
  coc.total_orders,
  CASE
    WHEN coc.total_orders = 1 THEN 'One-time'
    WHEN coc.total_orders = 2 THEN 'Returning'
    ELSE 'Loyal'
  END AS buyer_type
FROM customers c
JOIN customer_order_counts coc ON c.customer_id = coc.customer_id
ORDER BY coc.total_orders DESC;

-- Q7 — avg order value vs overall avg (CASE + CTE)  
WITH order_values AS (
  SELECT
    o.order_id,
    o.customer_id,
    SUM(p.price * oi.quantity * (1 - oi.discount)) AS order_value
  FROM orders     o
  JOIN order_items oi ON o.order_id   = oi.order_id
  JOIN products   p  ON oi.product_id = p.product_id
  WHERE o.status = 'Delivered'
  GROUP BY o.order_id, o.customer_id
),
overall AS (
  SELECT AVG(order_value) AS avg_val FROM order_values
)
SELECT
  ov.order_id,
  c.name,
  ROUND(ov.order_value, 2)  AS order_value,
  ROUND(o2.avg_val, 2)      AS overall_avg,
  CASE
    WHEN ov.order_value > o2.avg_val THEN 'Above avg'
    ELSE 'Below avg'
  END AS vs_avg
FROM order_values ov
JOIN overall o2 ON 1=1
JOIN customers c ON ov.customer_id = c.customer_id
ORDER BY ov.order_value DESC;

-- Q8 — return rate by category
 WITH category_stats AS (
  SELECT
    p.category,
    COUNT(o.order_id)                               AS total_orders,
    SUM(CASE WHEN o.status = 'Returned'
             THEN 1 ELSE 0 END)                  AS returned_orders
  FROM orders     o
  JOIN order_items oi ON o.order_id   = oi.order_id
  JOIN products   p  ON oi.product_id = p.product_id
  GROUP BY p.category
)
SELECT
  category,
  total_orders,
  returned_orders,
  ROUND(returned_orders * 100.0 / total_orders, 1) AS return_rate_pct
FROM category_stats
ORDER BY return_rate_pct DESC;

-- Q9 — payment mode preference by customer segment
SELECT
  c.segment,
  o.payment_mode,
  COUNT(*) AS usage_count,
  RANK() OVER (
    PARTITION BY c.segment
    ORDER BY COUNT(*) DESC
  ) AS preference_rank
FROM orders    o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.segment, o.payment_mode
ORDER BY c.segment, preference_rank;

-- Q10 — products never ordered (LEFT JOIN anti-pattern)
SELECT
  p.product_id,
  p.product_name,
  p.category,
  p.stock
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL
ORDER BY p.category;

