-- ============================================================
-- MTM4692 Applied SQL — Week 10 Practice
-- Topic: SQL Programming — Variables, Control Structures, Error Handling
-- Subtopic: SQLite Equivalents & Practical Examples
-- ============================================================
-- Topics Covered:
-- 1. Variables & Assignments (CTE as variables)
-- 2. Control Structures (CASE, Recursive CTEs as loops)
-- 3. Error Handling (ON CONFLICT, Transactions, Savepoints)
-- 4. Practical applications with real student data
-- 
-- Note: This file uses SQLite. For MySQL equivalents, see slides:
-- - Variables: DECLARE @var, DECLARE var ... DECLARE HANDLER
-- - Loops: WHILE, REPEAT, LOOP with LEAVE/ITERATE
-- - Error Handling: DECLARE HANDLER FOR error_code, SIGNAL, TRY...CATCH (SQL Server)
-- 
-- Run with: sqlite3 university.db < week10_practice.sql
-- ============================================================

PRAGMA foreign_keys = ON;
.headers on
.mode column

-- ============================================================
-- SECTION 1: CTE as Variables
-- ============================================================
-- SQLite has NO native variables (no DECLARE or @var)
-- Solution: Use CTEs to "store" computed values and reuse them
-- This is similar to MySQL's: SET @avg_gpa = (SELECT AVG(gpa) FROM student);
-- ============================================================

.print '\n=== CTE as Variables ==='

-- "Store" computed values and reuse them
WITH vars AS (
    SELECT
        AVG(gpa) AS avg_gpa,
        MIN(gpa) AS min_gpa,
        MAX(gpa) AS max_gpa,
        COUNT(*) AS total
    FROM student
)
SELECT
    ROUND(avg_gpa, 2) AS average,
    ROUND(min_gpa, 2) AS minimum,
    ROUND(max_gpa, 2) AS maximum,
    total AS count
FROM vars;

-- Use "variables" in a query
.print '\n=== Students vs Average ==='
WITH vars AS (
    SELECT AVG(gpa) AS avg_gpa FROM student
)
SELECT s.first_name, s.last_name, s.gpa,
       ROUND(v.avg_gpa, 2) AS class_avg,
       ROUND(s.gpa - v.avg_gpa, 2) AS diff,
       CASE
           WHEN s.gpa > v.avg_gpa THEN 'Above'
           WHEN s.gpa < v.avg_gpa THEN 'Below'
           ELSE 'At'
       END AS position
FROM student s, vars v
ORDER BY s.gpa DESC;

-- ============================================================
-- SECTION 2: CASE as IF/ELSE
-- ============================================================
-- SQLite ONLY supports CASE expressions in SELECT statements
-- MySQL supports full IF/ELSEIF/ELSE/END IF in procedures
-- Both achieve the same conditional logic, different syntax
-- CASE expression: Used in queries (SELECT, WHERE, ORDER BY)
-- MySQL IF/ELSE: Used in stored procedures/functions with BEGIN...END
-- ============================================================

.print '\n=== CASE as IF/ELSE ==='

-- Simple grading with CASE
SELECT first_name, gpa,
    CASE
        WHEN gpa >= 3.7 THEN 'A'
        WHEN gpa >= 3.3 THEN 'B+'
        WHEN gpa >= 3.0 THEN 'B'
        WHEN gpa >= 2.7 THEN 'C+'
        WHEN gpa >= 2.0 THEN 'C'
        WHEN gpa >= 1.0 THEN 'D'
        ELSE 'F'
    END AS letter_grade,
    CASE
        WHEN gpa >= 2.0 THEN 'PASS'
        ELSE 'FAIL'
    END AS pass_fail
FROM student
ORDER BY gpa DESC;

-- Nested CASE (simulates nested IF)
.print '\n=== Nested CASE ==='
SELECT first_name, gpa, dept_id,
    CASE
        WHEN gpa >= 3.5 THEN
            CASE dept_id
                WHEN 1 THEN '★ CS Honor Student'
                WHEN 2 THEN '★ Math Honor Student'
                ELSE '★ Honor Student'
            END
        WHEN gpa >= 2.0 THEN 'Good Standing'
        ELSE '⚠ Academic Probation'
    END AS status
FROM student
ORDER BY gpa DESC;

-- ============================================================
-- SECTION 3: Recursive CTE as LOOP
-- ============================================================
-- SQLite has NO native WHILE, REPEAT, or LOOP constructs
-- Solution: Use RECURSIVE CTEs to simulate iterative logic
-- This replaces MySQL's: WHILE...DO...END WHILE, REPEAT...UNTIL...END REPEAT
-- Each UNION ALL iteration simulates one loop iteration
-- ============================================================

.print '\n=== Recursive CTE = Loop ==='

-- "Loop" to generate multiplication table
WITH RECURSIVE mult AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM mult WHERE n < 12
)
SELECT n, n * 7 AS '7 × n' FROM mult;

-- Factorial "loop"
.print '\n=== Factorial ==='
WITH RECURSIVE fact AS (
    SELECT 1 AS n, 1 AS factorial
    UNION ALL
    SELECT n + 1, factorial * (n + 1)
    FROM fact WHERE n < 12
)
SELECT n, factorial FROM fact;

-- Compound interest "loop"
.print '\n=== Compound Interest (10% annually, $1000 initial) ==='
WITH RECURSIVE compound AS (
    SELECT 0 AS year, 1000.00 AS balance
    UNION ALL
    SELECT year + 1, ROUND(balance * 1.10, 2)
    FROM compound WHERE year < 20
)
SELECT year, balance,
       ROUND(balance - 1000, 2) AS interest_earned
FROM compound;

-- ============================================================
-- SECTION 4: Conditional Aggregation (IF-like logic)
-- ============================================================

.print '\n=== Conditional Counting ==='

-- Count by category (like IF in a loop)
SELECT
    COUNT(*) AS total,
    COUNT(CASE WHEN gpa >= 3.5 THEN 1 END) AS honors,
    COUNT(CASE WHEN gpa >= 2.0 AND gpa < 3.5 THEN 1 END) AS passing,
    COUNT(CASE WHEN gpa < 2.0 THEN 1 END) AS failing,
    ROUND(100.0 * COUNT(CASE WHEN gpa >= 3.5 THEN 1 END) / COUNT(*), 1) AS honor_pct
FROM student;

-- Per-department breakdown
.print '\n=== Per-Department Breakdown ==='
SELECT d.dept_name,
    COUNT(*) AS total,
    COUNT(CASE WHEN s.gpa >= 3.5 THEN 1 END) AS honors,
    COUNT(CASE WHEN s.gpa < 2.0 THEN 1 END) AS at_risk,
    ROUND(AVG(s.gpa), 2) AS avg_gpa
FROM student s
JOIN department d ON s.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

-- ============================================================
-- SECTION 5: Error Handling with ON CONFLICT
-- ============================================================
-- SQLite error handling uses CONSTRAINTS + ON CONFLICT strategies
-- MySQL uses: DECLARE HANDLER FOR error_code (specific errors)
-- SQL Server uses: BEGIN TRY...BEGIN CATCH...END CATCH (block-level)
--
-- Common Errors to Handle:
-- - 1062 (MySQL) / 2627 (SQL Server): Duplicate key (UNIQUE constraint)
-- - 1048 (MySQL) / 547 (SQL Server): Constraint violation
-- - 8134 (SQL Server): Divide by zero
--
-- SQLite Strategies:
-- INSERT OR IGNORE: Skip on conflict (no error, no insert)
-- INSERT OR REPLACE: Replace existing row
-- ON CONFLICT ... DO UPDATE: Upsert pattern (SQLite 3.24+)
-- Transactions + Savepoints: Control atomicity & rollback
-- ============================================================

.print '\n=== Error Handling: ON CONFLICT ==='

-- Create a test table
CREATE TABLE IF NOT EXISTS conflict_test (
    id INTEGER PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    score INTEGER DEFAULT 0
);

-- Normal insert
INSERT INTO conflict_test (email, name, score) VALUES ('a@test.com', 'Alice', 90);
INSERT INTO conflict_test (email, name, score) VALUES ('b@test.com', 'Bob', 85);

-- INSERT OR IGNORE: silently skip on conflict
INSERT OR IGNORE INTO conflict_test (email, name, score)
VALUES ('a@test.com', 'Alice Duplicate', 95);
-- No error, no insert

-- INSERT OR REPLACE: replace the row
INSERT OR REPLACE INTO conflict_test (id, email, name, score)
VALUES (1, 'a@test.com', 'Alice Updated', 95);

-- UPSERT with ON CONFLICT (SQLite 3.24+)
INSERT INTO conflict_test (email, name, score)
VALUES ('b@test.com', 'Bob', 90)
ON CONFLICT(email) DO UPDATE SET
    score = excluded.score,
    name = excluded.name;

SELECT * FROM conflict_test;
DROP TABLE conflict_test;

-- ============================================================
-- SECTION 6: Transactions & Savepoints (Error Handling via Atomicity)
-- ============================================================
-- SQLite lacks explicit error handlers, so uses TRANSACTIONS for safety
-- Atomicity: Either ALL changes succeed OR all are rolled back
-- This prevents partial updates that corrupt data
-- 
-- Comparison:
-- MySQL: DECLARE HANDLER FOR 1062 SET flag = 1; (explicit handling)
-- SQLite: BEGIN TRANSACTION...COMMIT or ROLLBACK (implicit handling)
-- SQL Server: BEGIN TRY...BEGIN CATCH...ROLLBACK (explicit + transaction)
-- ============================================================

.print '\n=== Transactions ==='

-- Atomicity demonstration
BEGIN TRANSACTION;
INSERT INTO student (first_name, last_name, dept_id, gpa)
VALUES ('Trans', 'Test1', 1, 3.0);
INSERT INTO student (first_name, last_name, dept_id, gpa)
VALUES ('Trans', 'Test2', 1, 3.5);
ROLLBACK;  -- Both undone

SELECT COUNT(*) AS trans_students FROM student WHERE first_name = 'Trans';
-- Should be 0

-- Savepoint for partial rollback
BEGIN TRANSACTION;
SAVEPOINT sp1;
INSERT INTO student (first_name, last_name, dept_id, gpa)
VALUES ('Save1', 'Test', 1, 3.0);

SAVEPOINT sp2;
INSERT INTO student (first_name, last_name, dept_id, gpa)
VALUES ('Save2', 'Test', 1, 3.5);

ROLLBACK TO sp2;  -- Only undo Save2
COMMIT;  -- Save1 is kept

.print '\n=== After Savepoint Test ==='
SELECT * FROM student WHERE first_name LIKE 'Save%';

-- Cleanup
DELETE FROM student WHERE first_name LIKE 'Save%';

-- ============================================================
-- SECTION 7: Complex Report (Variables + Logic + Loops)
-- ============================================================

.print '\n=== Comprehensive Student Report ==='

WITH
    class_stats AS (
        SELECT
            AVG(gpa) AS avg_gpa,
            MIN(gpa) AS min_gpa,
            MAX(gpa) AS max_gpa,
            COUNT(*) AS total
        FROM student
    ),
    student_ranked AS (
        SELECT s.first_name, s.last_name, s.gpa, d.dept_name,
               DENSE_RANK() OVER (ORDER BY s.gpa DESC) AS class_rank,
               DENSE_RANK() OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS dept_rank,
               NTILE(4) OVER (ORDER BY s.gpa DESC) AS quartile
        FROM student s
        JOIN department d ON s.dept_id = d.dept_id
    )
SELECT
    sr.class_rank AS '#',
    sr.first_name || ' ' || sr.last_name AS student,
    sr.dept_name AS department,
    sr.gpa,
    CASE
        WHEN sr.gpa >= 3.7 THEN 'A'
        WHEN sr.gpa >= 3.3 THEN 'B+'
        WHEN sr.gpa >= 3.0 THEN 'B'
        WHEN sr.gpa >= 2.0 THEN 'C'
        ELSE 'F'
    END AS grade,
    CASE sr.quartile
        WHEN 1 THEN 'Top 25%'
        WHEN 2 THEN 'Q2'
        WHEN 3 THEN 'Q3'
        WHEN 4 THEN 'Bottom 25%'
    END AS quartile,
    ROUND(sr.gpa - cs.avg_gpa, 2) AS vs_avg,
    CASE WHEN sr.dept_rank = 1 THEN '🏆' ELSE '' END AS dept_top
FROM student_ranked sr, class_stats cs
ORDER BY sr.class_rank;

-- ============================================================
-- SECTION 8: Date Series Report
-- ============================================================

.print '\n=== Weekly Report Template (Date Series) ==='

WITH RECURSIVE weeks AS (
    SELECT date('2025-01-06') AS week_start  -- First Monday
    UNION ALL
    SELECT date(week_start, '+7 days')
    FROM weeks WHERE week_start < '2025-04-30'
)
SELECT week_start,
       date(week_start, '+6 days') AS week_end,
       'Week ' || ((JULIANDAY(week_start) - JULIANDAY('2025-01-06')) / 7 + 1) AS week_num
FROM weeks;

-- ============================================================
-- SECTION 9: MySQL vs SQLite — Programming Features
-- ============================================================
-- Quick Reference (from slides):
--
-- Feature              | MySQL                    | SQLite
-- ==========================================
-- Variables            | DECLARE var, SET @var    | CTE as variable
-- IF/ELSE              | Full IF/ELSEIF/ELSE      | CASE expression
-- Loops                | WHILE, REPEAT, LOOP      | Recursive CTE
-- Error Handling       | DECLARE HANDLER FOR      | ON CONFLICT
-- Stored Procedures    | Full support (DELIMITER) | Not supported
-- Functions            | Full support             | Limited UDFs
-- Cursors              | Full support             | Not supported
-- Transactions         | BEGIN...COMMIT           | BEGIN...COMMIT
-- ============================================================

.print '\n✅ Week 10 practice complete!'
.print '\n📚 Key Takeaways:'
.print '   • SQLite limitations → Solutions using CTEs, CASE, Recursive CTEs'
.print '   • Error handling strategies differ: Explicit vs Implicit'
.print '   • Transactions provide safety when handlers unavailable'
.print '   • Understanding trade-offs helps choose right tool for job'
