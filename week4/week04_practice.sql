-- ============================================================
-- MTM4692 Applied SQL — Week 4 Practice
-- Topic: Indexes & Performance
-- ============================================================
-- Run with: sqlite3 university.db < week04_practice.sql

-- Or run interactively:

--   sqlite3 university.db
--   .read week04_practice.sql
-- ============================================================

-- ============================================================
-- SECTION 1: Setup and Configuration
-- ============================================================
PRAGMA foreign_keys = ON;
.headers on
.mode column
.timer on

-- ============================================================
-- SECTION 2: Check Existing Indexes
-- ============================================================

-- List all tables
.tables

-- List all indexes
.indexes

-- Show schema to see existing constraints (implicit indexes)
.schema student
.schema enrollment

-- ============================================================
-- SECTION 3: EXPLAIN Without Indexes
-- ============================================================

-- Full table scan: no index on last_name
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE last_name = 'Yılmaz';

-- Full table scan: no composite index
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE dept_id = 1 AND gpa >= 3.5;

-- Full table scan on JOIN
EXPLAIN QUERY PLAN
SELECT s.first_name, c.course_name, e.grade
FROM student s
JOIN enrollment e ON s.student_id = e.student_id
JOIN course c ON e.course_id = c.course_id;

-- ============================================================
-- SECTION 4: Single-Column Indexes
-- ============================================================

-- Create a basic index on last_name
CREATE INDEX IF NOT EXISTS idx_student_last_name ON student(last_name);

-- Verify index usage
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE last_name = 'Yılmaz';
-- Should show: SEARCH student USING INDEX idx_student_last_name

-- Index on foreign key column
CREATE INDEX IF NOT EXISTS idx_student_dept ON student(dept_id);

EXPLAIN QUERY PLAN
SELECT * FROM student WHERE dept_id = 1;
-- Should show: SEARCH student USING INDEX idx_student_dept

-- List indexes for student table
.indexes student

-- Index information
PRAGMA index_list(student);
PRAGMA index_info(idx_student_last_name);

-- ============================================================
-- SECTION 5: Composite Indexes
-- ============================================================

-- Composite index on (dept_id, gpa)
CREATE INDEX IF NOT EXISTS idx_student_dept_gpa ON student(dept_id, gpa);

-- Test: Both columns (leftmost prefix) → index used
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE dept_id = 1 AND gpa >= 3.5;

-- Test: Only leftmost column → index used
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE dept_id = 1;

-- Test: Only second column → index NOT used (leftmost prefix rule)
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE gpa >= 3.5;

-- Test: Order matters for ORDER BY
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE dept_id = 1 ORDER BY gpa DESC;

-- ============================================================
-- SECTION 6: Covering Indexes
-- ============================================================

-- Create a covering index for a common query
CREATE INDEX IF NOT EXISTS idx_covering_dept_student
ON student(dept_id, first_name, last_name, gpa);

-- This query can be answered entirely from the index
EXPLAIN QUERY PLAN
SELECT first_name, last_name, gpa
FROM student
WHERE dept_id = 1;
-- Should show: SEARCH USING COVERING INDEX

-- Drop to compare
DROP INDEX IF EXISTS idx_covering_dept_student;

-- Same query without covering index
EXPLAIN QUERY PLAN
SELECT first_name, last_name, gpa
FROM student
WHERE dept_id = 1;
-- Should show: SEARCH USING INDEX (then table lookup)

-- Recreate for later use
CREATE INDEX IF NOT EXISTS idx_covering_dept_student
ON student(dept_id, first_name, last_name, gpa);

-- ============================================================
-- SECTION 7: Partial Indexes (SQLite specialty)
-- ============================================================

-- Index only students with high GPA
CREATE INDEX IF NOT EXISTS idx_high_gpa
ON student(gpa) WHERE gpa >= 3.0;

EXPLAIN QUERY PLAN
SELECT * FROM student WHERE gpa >= 3.5;
-- Uses partial index

-- Index only graded enrollments
CREATE INDEX IF NOT EXISTS idx_graded_enrollment
ON enrollment(grade) WHERE grade IS NOT NULL;

EXPLAIN QUERY PLAN
SELECT * FROM enrollment WHERE grade = 'A';
-- Uses partial index

-- ============================================================
-- SECTION 8: Expression Indexes
-- ============================================================

-- Case-insensitive email search
CREATE INDEX IF NOT EXISTS idx_lower_email
ON student(LOWER(email));

EXPLAIN QUERY PLAN
SELECT * FROM student WHERE LOWER(email) = 'alice@ytu.edu.tr';
-- Uses expression index

-- ============================================================
-- SECTION 9: JOIN Performance with Indexes
-- ============================================================

-- Add indexes on foreign keys (critical for JOIN performance)
CREATE INDEX IF NOT EXISTS idx_enrollment_student ON enrollment(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_course ON enrollment(course_id);
CREATE INDEX IF NOT EXISTS idx_course_dept ON course(dept_id);

-- Check improved JOIN performance
EXPLAIN QUERY PLAN
SELECT s.first_name, s.last_name, c.course_name, e.grade
FROM student s
JOIN enrollment e ON s.student_id = e.student_id
JOIN course c ON e.course_id = c.course_id
WHERE s.dept_id = 1;

-- Complex query with multiple JOINs
EXPLAIN QUERY PLAN
SELECT d.dept_name,
       s.first_name || ' ' || s.last_name AS student_name,
       c.course_name,
       e.grade
FROM department d
JOIN student s ON d.dept_id = s.dept_id
JOIN enrollment e ON s.student_id = e.student_id
JOIN course c ON e.course_id = c.course_id
WHERE d.dept_name = 'Computer Science'
ORDER BY s.last_name;

-- ============================================================
-- SECTION 10: Index Anti-Patterns (What NOT To Do)
-- ============================================================

-- Anti-Pattern 1: Function on indexed column
-- ❌ BAD: function prevents index use
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE UPPER(last_name) = 'YILMAZ';
-- SCAN (full table scan)

-- ✅ FIX: Use expression index
CREATE INDEX IF NOT EXISTS idx_upper_last ON student(UPPER(last_name));
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE UPPER(last_name) = 'YILMAZ';
-- SEARCH using expression index

-- Anti-Pattern 2: Leading wildcard in LIKE
-- ❌ BAD: leading wildcard
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE last_name LIKE '%maz';
-- SCAN (full table scan)

-- ✅ OK: trailing wildcard uses index
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE last_name LIKE 'Yıl%';
-- SEARCH using index

-- Anti-Pattern 3: OR conditions on different columns
-- ❌ BAD: OR on different columns
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE last_name = 'Yılmaz' OR dept_id = 2;
-- May not use indexes efficiently

-- ✅ FIX: Use UNION
EXPLAIN QUERY PLAN
SELECT * FROM student WHERE last_name = 'Yılmaz'
UNION
SELECT * FROM student WHERE dept_id = 2;
-- Uses indexes for both parts

-- ============================================================
-- SECTION 11: Large Dataset Performance Test
-- ============================================================

-- Create a large test table
CREATE TABLE IF NOT EXISTS large_test (
    id INTEGER PRIMARY KEY,
    value1 TEXT,
    value2 INTEGER,
    value3 REAL,
    category TEXT,
    created_at TEXT
);

-- Insert 100,000 rows using recursive CTE
WITH RECURSIVE cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x + 1 FROM cnt WHERE x < 100000
)
INSERT OR IGNORE INTO large_test (value1, value2, value3, category, created_at)
SELECT
    'name_' || x,
    ABS(RANDOM() % 1000),
    ROUND(RANDOM() * 1.0 / 1000000000, 2),
    CASE ABS(RANDOM() % 5)
        WHEN 0 THEN 'A'
        WHEN 1 THEN 'B'
        WHEN 2 THEN 'C'
        WHEN 3 THEN 'D'
        ELSE 'E'
    END,
    date('2020-01-01', '+' || (ABS(RANDOM() % 1825)) || ' days')
FROM cnt;

SELECT COUNT(*) AS total_rows FROM large_test;

-- Test WITHOUT index
EXPLAIN QUERY PLAN
SELECT * FROM large_test WHERE value2 = 500;
-- SCAN large_test

SELECT COUNT(*) FROM large_test WHERE value2 = 500;
-- Note execution time

-- Create index
CREATE INDEX idx_large_value2 ON large_test(value2);

-- Test WITH index
EXPLAIN QUERY PLAN
SELECT * FROM large_test WHERE value2 = 500;
-- SEARCH using index

SELECT COUNT(*) FROM large_test WHERE value2 = 500;
-- Note execution time — should be faster

-- Range query with index
EXPLAIN QUERY PLAN
SELECT * FROM large_test WHERE value2 BETWEEN 100 AND 200;

-- Low-cardinality index (not very effective)
CREATE INDEX idx_large_category ON large_test(category);
EXPLAIN QUERY PLAN
SELECT * FROM large_test WHERE category = 'A';
-- Index used, but scans ~20% of table anyway

-- ============================================================
-- SECTION 12: ANALYZE Command
-- ============================================================

-- Collect statistics for the query optimizer
ANALYZE;

-- View collected statistics
SELECT * FROM sqlite_stat1;

-- ============================================================
-- SECTION 13: SQLite Performance PRAGMAs
-- ============================================================

-- Check current settings
PRAGMA journal_mode;
PRAGMA cache_size;
PRAGMA synchronous;
PRAGMA page_size;

-- Optimize for read performance
-- PRAGMA journal_mode = WAL;     -- Write-Ahead Logging
-- PRAGMA cache_size = -20000;    -- 20MB cache
-- PRAGMA synchronous = NORMAL;   -- Less durable, faster

-- Check database integrity
PRAGMA integrity_check;

-- ============================================================
-- SECTION 14: E-Commerce Database Indexing
-- ============================================================

-- Switch to e-commerce database
-- sqlite3 ecommerce.db

-- Recommended indexes for e-commerce queries

-- Orders table: frequently filtered by customer and date
-- CREATE INDEX idx_orders_customer ON orders(customer_id);
-- CREATE INDEX idx_orders_date ON orders(order_date);
-- CREATE INDEX idx_orders_status ON orders(status);

-- Order items: JOIN performance
-- CREATE INDEX idx_orderitem_order ON order_item(order_id);
-- CREATE INDEX idx_orderitem_product ON order_item(product_id);

-- Products: search by category and price
-- CREATE INDEX idx_product_category ON product(category_id);
-- CREATE INDEX idx_product_price ON product(price);

-- Composite: find products by category sorted by price
-- CREATE INDEX idx_product_cat_price ON product(category_id, price);

-- ============================================================
-- SECTION 15: Cleanup
-- ============================================================

-- Drop test table
DROP TABLE IF EXISTS large_test;

-- To remove practice indexes (if desired):
-- DROP INDEX IF EXISTS idx_student_last_name;
-- DROP INDEX IF EXISTS idx_student_dept;
-- DROP INDEX IF EXISTS idx_student_dept_gpa;
-- DROP INDEX IF EXISTS idx_covering_dept_student;
-- DROP INDEX IF EXISTS idx_high_gpa;
-- DROP INDEX IF EXISTS idx_graded_enrollment;
-- DROP INDEX IF EXISTS idx_lower_email;
-- DROP INDEX IF EXISTS idx_upper_last;
-- DROP INDEX IF EXISTS idx_enrollment_student;
-- DROP INDEX IF EXISTS idx_enrollment_course;
-- DROP INDEX IF EXISTS idx_course_dept;

.timer off
.print '✅ Week 4 practice complete!'
