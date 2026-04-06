-- ============================================================
-- MTM4692 Applied SQL — Week 7 Practice
-- Topic: Common Table Expressions (CTEs)
-- ============================================================
-- Run with: sqlite3 university.db < week07_practice.sql
-- ============================================================

PRAGMA foreign_keys = ON;
.headers on
.mode column

-- ============================================================
-- PART A: Simple CTEs
-- ============================================================

-- CTE: Departments with average GPA
.print '\n=== Departments with avg GPA > 3.0 ==='
WITH dept_avg AS (
    SELECT d.dept_name, ROUND(AVG(s.gpa), 2) AS avg_gpa
    FROM student s
    JOIN department d ON s.dept_id = d.dept_id
    GROUP BY d.dept_id
)
SELECT * FROM dept_avg WHERE avg_gpa > 3.0 ORDER BY avg_gpa DESC;

-- CTE: High GPA students (GPA >= 3.5)
.print '\n=== Students with GPA >= 3.5 ==='
WITH high_gpa AS (
    SELECT first_name, last_name, gpa FROM student WHERE gpa >= 3.5
)
SELECT * FROM high_gpa ORDER BY gpa DESC;

-- ============================================================
-- PART B: Multiple CTEs
-- ============================================================

-- Two CTEs chained together
.print '\n=== Students Above Their Department Average ==='
WITH dept_avg AS (
    SELECT dept_id, ROUND(AVG(gpa), 2) AS avg_gpa
    FROM student GROUP BY dept_id
),
above_avg AS (
    SELECT s.first_name, s.last_name, s.gpa, s.dept_id, da.avg_gpa
    FROM student s
    JOIN dept_avg da ON s.dept_id = da.dept_id
    WHERE s.gpa > da.avg_gpa
)
SELECT * FROM above_avg ORDER BY dept_id, gpa DESC;

-- ============================================================
-- PART C: Simple Recursive CTEs
-- ============================================================

-- Generate numbers 1 to 10
.print '\n=== Numbers 1 to 10 ==='
WITH RECURSIVE nums AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 10
)
SELECT n FROM nums;

-- Fibonacci series
.print '\n=== Fibonacci (first 10) ==='
WITH RECURSIVE fib AS (
    SELECT 0 AS a, 1 AS b
    UNION ALL
    SELECT b, a + b FROM fib WHERE b < 100
)
SELECT a AS fibonacci FROM fib;

-- Generate dates for one week
.print '\n=== April 7-13, 2026 ==='
WITH RECURSIVE dates AS (
    SELECT date('2026-04-07') AS d
    UNION ALL
    SELECT date(d, '+1 day') FROM dates WHERE d < '2026-04-13'
)
SELECT d, CASE CAST(strftime('%w', d) AS INTEGER)
    WHEN 0 THEN 'Sun'
    WHEN 1 THEN 'Mon'
    WHEN 2 THEN 'Tue'
    WHEN 3 THEN 'Wed'
    WHEN 4 THEN 'Thu'
    WHEN 5 THEN 'Fri'
    WHEN 6 THEN 'Sat'
END AS day
FROM dates;

-- ============================================================
-- PART D: Simple Hierarchy (Employee)
-- ============================================================

CREATE TABLE IF NOT EXISTS emp_hierarchy (
    emp_id INTEGER PRIMARY KEY,
    name TEXT,
    title TEXT,
    manager_id INTEGER
);

DELETE FROM emp_hierarchy;
INSERT INTO emp_hierarchy VALUES
(1, 'Ayşe', 'CEO', NULL),
(2, 'Mehmet', 'CTO', 1),
(3, 'Fatma', 'CFO', 1),
(4, 'Ali', 'Dev Lead', 2);

-- Simple hierarchy
.print '\n=== Company Org Chart ==='
WITH RECURSIVE org AS (
    SELECT emp_id, name, title, manager_id, 0 AS level
    FROM emp_hierarchy WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.name, e.title, e.manager_id, o.level + 1
    FROM emp_hierarchy e
    JOIN org o ON e.manager_id = o.emp_id
)
SELECT SUBSTR('    ', 1, level * 2) || name AS name, title, level
FROM org ORDER BY level, emp_id;

-- ============================================================
-- Cleanup
-- ============================================================
DROP TABLE IF EXISTS emp_hierarchy;

.print '✅ Week 7 practice complete!'
