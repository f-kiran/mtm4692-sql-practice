-- ============================================================
-- MTM4692 Applied SQL — Week 2: SQL Fundamentals
-- Practice Code File
-- ============================================================
-- Run with: sqlite3 ecommerce.db < week02_practice.sql
-- Or interactively: sqlite3 ecommerce.db
-- Then: .read week02_practice.sql
-- ============================================================

-- ============================================================
-- SETUP
-- ============================================================
.headers on
.mode column
PRAGMA foreign_keys = ON;

-- ============================================================
-- SECTION 1: Create E-Commerce Database
-- ============================================================

DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS customer;

-- Categories
CREATE TABLE category (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE,
    description   TEXT
);

-- Products
CREATE TABLE product (
    product_id    INTEGER PRIMARY KEY,
    product_name  TEXT NOT NULL,
    category_id   INTEGER,
    price_cents   INTEGER NOT NULL CHECK (price_cents > 0),
    stock_qty     INTEGER DEFAULT 0 CHECK (stock_qty >= 0),
    is_active     INTEGER DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at    TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- Customers
CREATE TABLE customer (
    customer_id  INTEGER PRIMARY KEY,
    first_name   TEXT NOT NULL,
    last_name    TEXT NOT NULL,
    email        TEXT UNIQUE NOT NULL,
    phone        TEXT,
    city         TEXT DEFAULT 'Istanbul',
    created_at   TEXT DEFAULT (datetime('now'))
);

-- Orders
CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL,
    order_date   TEXT DEFAULT (datetime('now')),
    status       TEXT DEFAULT 'pending'
                 CHECK (status IN ('pending','processing','shipped','delivered','cancelled')),
    total_cents  INTEGER DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- Order Items
CREATE TABLE order_item (
    item_id      INTEGER PRIMARY KEY,
    order_id     INTEGER NOT NULL,
    product_id   INTEGER NOT NULL,
    quantity     INTEGER NOT NULL CHECK (quantity > 0),
    unit_price   INTEGER NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);

-- ============================================================
-- SECTION 2: Insert Sample Data
-- ============================================================

INSERT INTO category (category_name, description) VALUES
    ('Electronics', 'Electronic devices and gadgets'),
    ('Books', 'Physical and digital books'),
    ('Clothing', 'Apparel and accessories'),
    ('Sports', 'Sports equipment and gear');

INSERT INTO product (product_name, category_id, price_cents, stock_qty) VALUES
    ('Wireless Mouse', 1, 2999, 150),
    ('USB-C Hub', 1, 4999, 75),
    ('Mechanical Keyboard', 1, 7999, 60),
    ('Python Crash Course', 2, 3499, 200),
    ('SQL Pocket Guide', 2, 1999, 120),
    ('Clean Code', 2, 4299, 90),
    ('Running Shoes', 3, 8999, 50),
    ('Cotton T-Shirt', 3, 1499, 300),
    ('Winter Jacket', 3, 12999, 40),
    ('Yoga Mat', 4, 2499, 80),
    ('Dumbbell Set', 4, 5999, 40),
    ('Jump Rope', 4, 999, 200);

INSERT INTO customer (first_name, last_name, email, phone, city) VALUES
    ('Ahmet',  'Yılmaz', 'ahmet@email.com',  '555-0101', 'Istanbul'),
    ('Ayşe',   'Kara',   'ayse@email.com',   '555-0102', 'Ankara'),
    ('Mehmet', 'Demir',  'mehmet@email.com',  '555-0103', 'Izmir'),
    ('Zeynep', 'Çelik',  'zeynep@email.com', NULL,        'Istanbul'),
    ('Can',    'Öz',     'can@email.com',     '555-0105', 'Bursa'),
    ('Deniz',  'Ak',     'deniz@email.com',   NULL,        'Antalya'),
    ('Ece',    'Tan',    'ece@email.com',     '555-0107', 'Istanbul');

INSERT INTO orders (customer_id, order_date, status, total_cents) VALUES
    (1, '2025-01-15 10:30:00', 'delivered', 7998),
    (1, '2025-02-20 14:15:00', 'shipped', 3499),
    (2, '2025-02-25 09:00:00', 'processing', 10998),
    (3, '2025-03-01 11:45:00', 'pending', 2999),
    (4, '2025-01-10 16:20:00', 'delivered', 14998),
    (4, '2025-02-28 08:00:00', 'shipped', 5999),
    (5, '2025-01-20 12:00:00', 'delivered', 1999),
    (2, '2025-03-01 10:00:00', 'pending', 999);

INSERT INTO order_item (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 2, 2999),
    (2, 4, 1, 3499),
    (3, 7, 1, 8999),
    (3, 5, 1, 1999),
    (4, 1, 1, 2999),
    (5, 7, 1, 8999),
    (5, 10, 1, 2499),
    (5, 8, 2, 1499),
    (6, 11, 1, 5999),
    (7, 5, 1, 1999),
    (8, 12, 1, 999);

-- ============================================================
-- SECTION 3: Data Type & Type Affinity Exercises
-- ============================================================

SELECT '=== Section 3: Type Affinity ===';

-- Check types of values
SELECT typeof(42) AS int_type,
       typeof(3.14) AS real_type,
       typeof('hello') AS text_type,
       typeof(NULL) AS null_type,
       typeof(X'CAFE') AS blob_type;

-- CAST examples
SELECT CAST('42' AS INTEGER) AS str_to_int,
       CAST(3.14 AS INTEGER) AS real_to_int,
       CAST(42 AS TEXT) AS int_to_text;

-- ============================================================
-- SECTION 4: Constraint Demonstrations
-- ============================================================

SELECT '=== Section 4: Constraints in Action ===';

-- NOT NULL violation
-- INSERT INTO customer (last_name, email) VALUES ('Test', 'test@email.com');
-- ERROR: NOT NULL constraint failed: customer.first_name

-- UNIQUE violation
-- INSERT INTO customer (first_name, last_name, email) VALUES ('Test', 'User', 'ahmet@email.com');
-- ERROR: UNIQUE constraint failed: customer.email

-- CHECK violation
-- INSERT INTO product (product_name, category_id, price_cents) VALUES ('Bad', 1, -100);
-- ERROR: CHECK constraint failed

-- FOREIGN KEY violation
-- INSERT INTO orders (customer_id, status) VALUES (999, 'pending');
-- ERROR: FOREIGN KEY constraint failed

SELECT '(Constraint violations are commented out - uncomment to test)';

-- ============================================================
-- SECTION 5: INSERT Patterns
-- ============================================================

SELECT '=== Section 5: INSERT Patterns ===';

-- INSERT OR IGNORE (skip on conflict)
INSERT OR IGNORE INTO customer (first_name, last_name, email)
VALUES ('Ahmet', 'Yılmaz', 'ahmet@email.com');
-- No error, silently ignored because email exists

-- INSERT OR REPLACE
INSERT OR REPLACE INTO category (category_id, category_name, description)
VALUES (1, 'Electronics', 'Updated: Electronic devices, gadgets, and accessories');

SELECT '--- Updated Electronics category ---';
SELECT * FROM category WHERE category_id = 1;

-- ============================================================
-- SECTION 6: UPDATE Exercises
-- ============================================================

SELECT '=== Section 6: UPDATE Exercises ===';

-- 6.1: Increase price of all Electronics by 10%
UPDATE product
SET price_cents = CAST(price_cents * 1.10 AS INTEGER)
WHERE category_id = 1;

SELECT '--- Electronics after 10% price increase ---';
SELECT product_name, PRINTF('$%.2f', price_cents / 100.0) AS price
FROM product
WHERE category_id = 1;

-- 6.2: Conditional update with CASE
UPDATE product
SET is_active = CASE
    WHEN stock_qty = 0 THEN 0
    ELSE 1
END;

-- 6.3: Update with calculation
UPDATE product
SET stock_qty = stock_qty - 5
WHERE product_name = 'Wireless Mouse';

SELECT '--- Mouse stock after selling 5 ---';
SELECT product_name, stock_qty FROM product WHERE product_id = 1;

-- ============================================================
-- SECTION 7: String Functions
-- ============================================================

SELECT '=== Section 7: String Functions ===';

-- 7.1: Full name concatenation
SELECT '--- Customer Full Names ---';
SELECT first_name || ' ' || last_name AS full_name
FROM customer;

-- 7.2: Uppercase and lowercase
SELECT UPPER(product_name) AS upper_name,
       LOWER(product_name) AS lower_name
FROM product LIMIT 3;

-- 7.3: String length
SELECT product_name, LENGTH(product_name) AS name_length
FROM product
ORDER BY name_length DESC;

-- 7.4: Substring and INSTR
SELECT '--- Email Domains ---';
SELECT email,
       SUBSTR(email, INSTR(email, '@') + 1) AS domain
FROM customer;

-- 7.5: REPLACE
SELECT REPLACE('Hello World', 'World', 'SQLite') AS replaced;

-- 7.6: TRIM
SELECT TRIM('   spaces   ') AS trimmed;

-- 7.7: LIKE pattern matching
SELECT '--- Products containing "o" ---';
SELECT product_name FROM product WHERE product_name LIKE '%o%';

-- 7.8: PRINTF formatting
SELECT PRINTF('%-20s $%8.2f  Qty: %d', product_name, price_cents/100.0, stock_qty) AS formatted
FROM product;

-- ============================================================
-- SECTION 8: Numeric Functions
-- ============================================================

SELECT '=== Section 8: Numeric Functions ===';

-- 8.1: ROUND
SELECT ROUND(3.14159, 2) AS rounded;

-- 8.2: ABS
SELECT ABS(-42) AS absolute;

-- 8.3: MIN, MAX of values
SELECT MIN(10, 20, 5) AS min_val, MAX(10, 20, 5) AS max_val;

-- 8.4: Random number (0-99)
SELECT ABS(RANDOM() % 100) AS random_0_to_99;

-- 8.5: Modulo
SELECT 17 % 5 AS modulo_result;

-- ============================================================
-- SECTION 9: Date/Time Functions
-- ============================================================

SELECT '=== Section 9: Date/Time Functions ===';

-- 9.1: Current date and time
SELECT date('now') AS today,
       time('now') AS current_time,
       datetime('now') AS now;

-- 9.2: Date arithmetic
SELECT date('now', '+7 days') AS next_week,
       date('now', '-1 month') AS last_month,
       date('now', 'start of month') AS month_start;

-- 9.3: Extract parts with strftime
SELECT strftime('%Y', 'now') AS year,
       strftime('%m', 'now') AS month,
       strftime('%d', 'now') AS day,
       strftime('%w', 'now') AS day_of_week;

-- 9.4: Days since each order
SELECT '--- Order Age (days) ---';
SELECT order_id,
       order_date,
       CAST(julianday('now') - julianday(order_date) AS INTEGER) AS days_ago
FROM orders
ORDER BY days_ago;

-- 9.5: Orders per month
SELECT '--- Orders by Month ---';
SELECT strftime('%Y-%m', order_date) AS month,
       COUNT(*) AS order_count
FROM orders
GROUP BY month
ORDER BY month;

-- ============================================================
-- SECTION 10: NULL Handling
-- ============================================================

SELECT '=== Section 10: NULL Handling ===';

-- 10.1: COALESCE
SELECT '--- Phone numbers (COALESCE) ---';
SELECT first_name,
       COALESCE(phone, 'No phone') AS phone
FROM customer;

-- 10.2: IFNULL (same as COALESCE for 2 args)
SELECT first_name,
       IFNULL(phone, 'N/A') AS phone
FROM customer;

-- 10.3: NULLIF
SELECT NULLIF(0, 0) AS returns_null,
       NULLIF(42, 0) AS returns_42;

-- 10.4: IS NULL / IS NOT NULL
SELECT '--- Customers without phone ---';
SELECT first_name, last_name
FROM customer
WHERE phone IS NULL;

-- ============================================================
-- SECTION 11: CASE Expressions
-- ============================================================

SELECT '=== Section 11: CASE Expressions ===';

-- 11.1: Price tier categorization
SELECT '--- Product Price Tiers ---';
SELECT product_name,
       PRINTF('$%.2f', price_cents / 100.0) AS price,
       CASE
           WHEN price_cents >= 8000 THEN 'Premium'
           WHEN price_cents >= 3000 THEN 'Standard'
           ELSE 'Budget'
       END AS tier
FROM product
ORDER BY price_cents DESC;

-- 11.2: Order status display
SELECT '--- Order Status Display ---';
SELECT order_id, customer_id,
       CASE status
           WHEN 'delivered'  THEN '✅ Delivered'
           WHEN 'shipped'    THEN '📦 Shipped'
           WHEN 'processing' THEN '⚙️  Processing'
           WHEN 'pending'    THEN '⏳ Pending'
           WHEN 'cancelled'  THEN '❌ Cancelled'
       END AS display_status
FROM orders;

-- 11.3: IIF (inline if - SQLite 3.32+)
SELECT product_name,
       stock_qty,
       IIF(stock_qty < 50, 'Low Stock!', 'OK') AS stock_status
FROM product;

-- ============================================================
-- SECTION 12: Aggregate Functions Review
-- ============================================================

SELECT '=== Section 12: Aggregate Functions ===';

-- 12.1: Basic aggregates
SELECT COUNT(*) AS total_products,
       PRINTF('$%.2f', AVG(price_cents) / 100.0) AS avg_price,
       PRINTF('$%.2f', MIN(price_cents) / 100.0) AS min_price,
       PRINTF('$%.2f', MAX(price_cents) / 100.0) AS max_price,
       SUM(stock_qty) AS total_stock
FROM product;

-- 12.2: Per-category stats
SELECT '--- Stats by Category ---';
SELECT c.category_name,
       COUNT(*) AS products,
       PRINTF('$%.2f', AVG(p.price_cents) / 100.0) AS avg_price,
       SUM(p.stock_qty) AS total_stock
FROM product p, category c
WHERE p.category_id = c.category_id
GROUP BY c.category_name;

-- 12.3: Orders per customer
SELECT '--- Orders per Customer ---';
SELECT c.first_name || ' ' || c.last_name AS customer,
       COUNT(o.order_id) AS num_orders,
       PRINTF('$%.2f', SUM(o.total_cents) / 100.0) AS total_spent
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
ORDER BY total_spent DESC;

-- ============================================================
-- SECTION 13: Complete Table Summary
-- ============================================================

SELECT '=== Database Summary ===';
SELECT 'category'   AS table_name, COUNT(*) AS rows FROM category
UNION ALL
SELECT 'product',    COUNT(*) FROM product
UNION ALL
SELECT 'customer',   COUNT(*) FROM customer
UNION ALL
SELECT 'orders',     COUNT(*) FROM orders
UNION ALL
SELECT 'order_item', COUNT(*) FROM order_item;

-- ============================================================
-- END OF WEEK 2 PRACTICE
-- ============================================================
SELECT '✅ Week 2 practice complete!';
