-- ============================================================
-- MTM4692 Applied SQL — Week 6 Practice
-- Topic: Relational vs NoSQL — JSON in SQLite
-- ============================================================
-- Run with: sqlite3 practice.db < week06_practice.sql
-- OR 
-- Run sqlite3 practice.db and paste sections to explore interactively
-- ============================================================

PRAGMA foreign_keys = ON;
.headers on
.mode column

-- ============================================================
-- SECTION 1: ACID Demonstration on Bank Accounts
-- ============================================================

-- Create a simple bank accounts table
CREATE TABLE IF NOT EXISTS accounts (
    account_id INTEGER PRIMARY KEY,
    holder_name TEXT NOT NULL,
    balance REAL NOT NULL CHECK (balance >= 0)
);

INSERT OR IGNORE INTO accounts VALUES (1, 'Alice', 1000.00);
INSERT OR IGNORE INTO accounts VALUES (2, 'Bob', 500.00);

.print '\n--- Initial Balances ---'
SELECT * FROM accounts;

-- Atomicity: successful transaction
BEGIN TRANSACTION;
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;
COMMIT;

.print '\n--- After Transfer (committed) ---'
SELECT * FROM accounts;

-- Atomicity: rolled back transaction
BEGIN TRANSACTION;
UPDATE accounts SET balance = balance - 5000 WHERE account_id = 1;
-- Oops! This would make balance negative
ROLLBACK;

.print '\n--- After Rollback (unchanged) ---'
SELECT * FROM accounts;

-- ============================================================
-- SECTION 2: JSON Basics
-- ============================================================

-- Create a product catalog with JSON specs
CREATE TABLE IF NOT EXISTS product_catalog (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    base_price REAL NOT NULL,
    specs TEXT  -- JSON
);

DELETE FROM product_catalog; -- Clear existing data for repeatable runs

INSERT INTO product_catalog VALUES
(1, 'MacBook Pro 14', 'Laptop', 2499.00,
 '{"brand":"Apple","ram":16,"storage":512,"cpu":"M3","screen":14.2}'),
(2, 'ThinkPad X1 Carbon', 'Laptop', 1799.00,
 '{"brand":"Lenovo","ram":32,"storage":1024,"cpu":"i7-1365U","screen":14}'),
(3, 'Dell XPS 15', 'Laptop', 1999.00,
 '{"brand":"Dell","ram":16,"storage":512,"cpu":"i7-13700H","screen":15.6}'),
(4, 'iPhone 15 Pro', 'Phone', 1199.00,
 '{"brand":"Apple","storage":256,"color":"Blue","5g":true,"chip":"A17 Pro"}'),
(5, 'Galaxy S24 Ultra', 'Phone', 1299.00,
 '{"brand":"Samsung","storage":256,"color":"Titanium","5g":true,"chip":"Snapdragon 8 Gen 3"}'),
(6, 'Pixel 8 Pro', 'Phone', 999.00,
 '{"brand":"Google","storage":128,"color":"Bay","5g":true,"chip":"Tensor G3"}'),
(7, 'iPad Air M2', 'Tablet', 599.00,
 '{"brand":"Apple","storage":64,"screen":10.9,"cellular":false}'),
(8, 'Galaxy Tab S9', 'Tablet', 849.00,
 '{"brand":"Samsung","storage":128,"screen":11,"cellular":true}');

-- ============================================================
-- SECTION 3: Extracting JSON Values
-- ============================================================

.print '\n--- JSON Extract ---'

-- Extracting specific fields from JSON specs for laptops
SELECT name,
       json_extract(specs, '$.brand') AS brand,
       json_extract(specs, '$.ram') AS ram_gb,
       json_extract(specs, '$.storage') AS storage_gb
FROM product_catalog
WHERE category = 'Laptop';

-- All Apple products
.print '\n--- Apple Products ---'
SELECT name, base_price, category
FROM product_catalog
WHERE json_extract(specs, '$.brand') = 'Apple';

-- Phones with 5G
.print '\n--- 5G Phones ---'
SELECT name, json_extract(specs, '$.chip') AS chip
FROM product_catalog
WHERE json_extract(specs, '$.5g') = 1;

-- Laptops with 16+ GB RAM
.print '\n--- High RAM Laptops ---'
SELECT name,
       json_extract(specs, '$.ram') AS ram,
       json_extract(specs, '$.cpu') AS cpu
FROM product_catalog
WHERE category = 'Laptop'
  AND json_extract(specs, '$.ram') >= 16;

-- ============================================================
-- SECTION 4: JSON Modification
-- ============================================================

-- json_set: update existing value
UPDATE product_catalog
SET specs = json_set(specs, '$.ram', 64)
WHERE product_id = 2;

-- json_insert: add new field (won't overwrite existing)
UPDATE product_catalog
SET specs = json_insert(specs, '$.warranty', '3 years')
WHERE product_id = 1;

-- json_replace: update only if exists
UPDATE product_catalog
SET specs = json_replace(specs, '$.color', 'Graphite')
WHERE product_id = 5;

-- json_remove: remove a field
UPDATE product_catalog
SET specs = json_remove(specs, '$.cellular')
WHERE product_id = 7;

-- Verify changes
.print '\n--- After JSON Modifications ---'
SELECT name, specs FROM product_catalog WHERE product_id IN (1, 2, 5, 7);

-- ============================================================
-- SECTION 5: JSON Arrays
-- https://www.postgresql.org/docs/9.3/functions-json.html
-- ============================================================

CREATE TABLE IF NOT EXISTS tagged_items (
    id INTEGER PRIMARY KEY,
    name TEXT,
    tags TEXT  -- JSON array
); -- close db browser to avoid locking issues, if it's open

DELETE FROM tagged_items; -- Clear existing data for repeatable runs

INSERT INTO tagged_items VALUES
(1, 'Gaming Laptop', '["gaming","laptop","high-performance","rgb"]'),
(2, 'Business Laptop', '["business","laptop","portable","lightweight"]'),
(3, 'Gaming Mouse', '["gaming","mouse","rgb","wireless"]'),
(4, 'Webcam HD', '["video","streaming","business"]'),
(5, 'Mechanical Keyboard', '["gaming","keyboard","rgb","mechanical"]');

-- Count tags per item
.print '\n--- Tag Counts ---'
SELECT name, json_array_length(tags) AS tag_count
FROM tagged_items;

-- Items with 'gaming' tag
.print '\n--- Gaming Items ---'
SELECT name FROM tagged_items
WHERE EXISTS (
    SELECT 1 FROM json_each(tags) WHERE value = 'gaming'
);

-- Items with 'rgb' tag
.print '\n--- RGB Items ---'
SELECT name FROM tagged_items
WHERE EXISTS (
    SELECT 1 FROM json_each(tags) WHERE value = 'rgb'
);

-- Expand all tags (one row per tag)
-- Note: This will create multiple rows for items with multiple tags
.print '\n--- Expanded Tags ---'
SELECT t.name, j.value AS tag
FROM tagged_items t, json_each(t.tags) j
ORDER BY t.name, j.value;

-- Tag frequency analysis
-- Count how many items have each tag (tags can be shared across items)
.print '\n--- Tag Frequency ---'
SELECT j.value AS tag, COUNT(*) AS item_count
FROM tagged_items t, json_each(t.tags) j
GROUP BY j.value
ORDER BY item_count DESC;

-- ============================================================
-- SECTION 6: Hybrid SQL + JSON Reporting
-- ============================================================

-- Category summary with brand info from JSON
.print '\n--- Category Summary ---'
SELECT category,
       COUNT(*) AS product_count,
       ROUND(AVG(base_price), 2) AS avg_price,
       ROUND(MIN(base_price), 2) AS min_price,
       ROUND(MAX(base_price), 2) AS max_price,
       GROUP_CONCAT(DISTINCT json_extract(specs, '$.brand')) AS brands
FROM product_catalog
GROUP BY category
ORDER BY avg_price DESC;

-- Brand comparison
.print '\n--- Brand Comparison ---'
SELECT json_extract(specs, '$.brand') AS brand,
       COUNT(*) AS products,
       ROUND(AVG(base_price), 2) AS avg_price,
       GROUP_CONCAT(category) AS categories
FROM product_catalog
GROUP BY json_extract(specs, '$.brand')
ORDER BY products DESC;

-- Storage analysis across all products
.print '\n--- Storage Analysis ---'
SELECT name, category,
       json_extract(specs, '$.storage') AS storage_gb,
       base_price,
       ROUND(base_price / json_extract(specs, '$.storage'), 2) AS price_per_gb
FROM product_catalog
ORDER BY price_per_gb;

-- ============================================================
-- SECTION 7: Event Store (Document-Style)
-- ============================================================

-- Simulate a NoSQL-style event store in SQLite
CREATE TABLE IF NOT EXISTS events (
    event_id INTEGER PRIMARY KEY,
    event_type TEXT NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (datetime('now')),
    data TEXT NOT NULL  -- JSON payload
);

DELETE FROM events; -- Clear existing data for repeatable runs

INSERT INTO events (event_type, timestamp, data) VALUES
('page_view', '2025-01-15 10:30:00',
 '{"user_id":42,"page":"/products","referrer":"google.com"}'),
('add_to_cart', '2025-01-15 10:31:00',
 '{"user_id":42,"product_id":1,"quantity":1}'),
('purchase', '2025-01-15 10:35:00',
 '{"user_id":42,"order_id":1001,"total":2499.00,"items":[1]}'),
('page_view', '2025-01-15 11:00:00',
 '{"user_id":99,"page":"/about","referrer":"twitter.com"}'),
('signup', '2025-01-15 11:05:00',
 '{"user_id":100,"email":"new@example.com","source":"organic"}');

-- Query events by type
.print '\n--- Page Views ---'
SELECT event_id, timestamp,
       json_extract(data, '$.user_id') AS user_id,
       json_extract(data, '$.page') AS page
FROM events
WHERE event_type = 'page_view';

-- Event type frequency
.print '\n--- Event Frequency ---'
SELECT event_type, COUNT(*) AS count
FROM events
GROUP BY event_type
ORDER BY count DESC;

-- User activity
.print '\n--- User 42 Activity ---'
SELECT event_type, timestamp,
       json_extract(data, '$.page') AS page,
       json_extract(data, '$.product_id') AS product,
       json_extract(data, '$.total') AS total
FROM events
WHERE json_extract(data, '$.user_id') = 42
ORDER BY timestamp;

-- ============================================================
-- SECTION 8: Cleanup
-- ============================================================

-- DROP TABLE IF EXISTS accounts;
-- DROP TABLE IF EXISTS product_catalog;
-- DROP TABLE IF EXISTS tagged_items;
-- DROP TABLE IF EXISTS events;

.print '✅ Week 6 practice complete!'
