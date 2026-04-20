-- ============================================================================
-- MTM4692 Applied SQL — Week 9 Practice
-- Topic: Window Functions & Pivot/Unpivot Practice Exercises
-- ============================================================================
-- HOW TO RUN:
-- 
-- Option 1 - University Database (basic output):
--   sqlite3 databases/university.db < week09_practice.sql
--
-- Option 2 - University Database (formatted output):
--   sqlite3 -header -column databases/university.db < week09_practice.sql
--
-- Option 3 - E-Commerce Database:
--   sqlite3 -header -column databases/ecommerce.db < week09_practice.sql
--
-- Option 4 - Interactive mode (to run queries one by one):
--   sqlite3 databases/university.db
--   Then paste SQL code into the SQLite CLI
--
-- Note: If using ATTACH DATABASE syntax, ensure this script is run from the 
--       directory containing the 'databases' folder (usually the slides folder)
-- ============================================================================

-- ============================================================================
-- DATABASE SETUP - ATTACH DATABASES
-- ============================================================================
-- Run one of the following to connect to the desired database:

-- Option 1: University Database (for student, department, enrollment, course tables)
-- .open databases/university.db

-- Option 2: E-Commerce Database (for orders, customers, products tables)
-- .open databases/ecommerce.db

-- Option 3: Book Database (for author, book, publisher tables)
-- .open databases/longlist.db

-- Or use ATTACH DATABASE to work with multiple databases simultaneously:
sqlite3
ATTACH DATABASE 'databases/university.db' AS university;
ATTACH DATABASE 'databases/ecommerce.db' AS ecommerce;
ATTACH DATABASE 'databases/longlist.db' AS longlist;

-- After attaching, reference tables as:
--   university.student, university.enrollment, etc.
--   ecommerce.orders, ecommerce.customers, etc.
--   longlist.author, longlist.book, etc.

-- Enable formatting for output
PRAGMA foreign_keys = ON;
.headers on
.mode column

-- ============================================================================
-- PART 1: WINDOW FUNCTIONS - RANKING
-- ============================================================================
-- Note: All examples below use the university.db database
-- If using ATTACH DATABASE syntax, prefix table names with 'university.'
-- Examples: university.student, university.enrollment, university.course, etc.
--

-- 1.1: ROW_NUMBER() - Basic ranking
-- Assigns unique sequential number to each row
SELECT first_name, last_name, dept_id, gpa,
       ROW_NUMBER() OVER (
           PARTITION BY dept_id ORDER BY gpa DESC
       ) AS rank_in_dept
FROM student;

-- 1.2: RANK() vs DENSE_RANK() - Handling ties
SELECT first_name, gpa,
       ROW_NUMBER() OVER (ORDER BY gpa DESC) AS row_num,
       RANK()       OVER (ORDER BY gpa DESC) AS rank,
       DENSE_RANK() OVER (ORDER BY gpa DESC) AS dense_rank
FROM student;

-- 1.3: RANK() comparison with DENSE_RANK()
-- RANK: Ties get same rank, gaps after ties (1, 2, 2, 4, 5)
-- DENSE_RANK: Ties get same rank, no gaps (1, 2, 2, 3, 4)
SELECT first_name, gpa,
       ROW_NUMBER() OVER (ORDER BY gpa DESC) AS row_num,
       RANK()       OVER (ORDER BY gpa DESC) AS rank,
       DENSE_RANK() OVER (ORDER BY gpa DESC) AS dense_rank
FROM student
ORDER BY gpa DESC;

-- 1.4: NTILE(n) - Divide into buckets
-- Divide students into 4 quartiles by GPA
SELECT first_name, gpa,
       NTILE(4) OVER (ORDER BY gpa DESC) AS quartile
FROM student
ORDER BY quartile, gpa DESC;

-- 1.5: NTILE with categorization
-- Grading on a curve: top 10% get A+, etc.
SELECT first_name, gpa,
       NTILE(10) OVER (ORDER BY gpa DESC) AS decile,
       CASE
           WHEN NTILE(10) OVER (ORDER BY gpa DESC) = 1 THEN 'A+'
           WHEN NTILE(10) OVER (ORDER BY gpa DESC) <= 3 THEN 'A'
           WHEN NTILE(10) OVER (ORDER BY gpa DESC) <= 5 THEN 'B'
           WHEN NTILE(10) OVER (ORDER BY gpa DESC) <= 7 THEN 'C'
           ELSE 'D'
       END AS curved_grade
FROM student
ORDER BY decile;

-- 1.6: Find top 3 students in each department
WITH ranked AS (
    SELECT first_name, last_name, dept_id, gpa,
           DENSE_RANK() OVER (
               PARTITION BY dept_id ORDER BY gpa DESC
           ) AS dept_rank
    FROM student
)
SELECT *
FROM ranked
WHERE dept_rank <= 3
ORDER BY dept_id, dept_rank;

-- ============================================================================
-- PART 2: AGGREGATE WINDOW FUNCTIONS
-- ============================================================================

-- 2.1: Aggregate windows with PARTITION BY
SELECT first_name, dept_id, gpa,
       COUNT(*) OVER (PARTITION BY dept_id) AS dept_size,
       ROUND(AVG(gpa) OVER (PARTITION BY dept_id), 2) AS dept_avg,
       MAX(gpa) OVER (PARTITION BY dept_id) AS dept_max,
       MIN(gpa) OVER (PARTITION BY dept_id) AS dept_min,
       ROUND(gpa - AVG(gpa) OVER (PARTITION BY dept_id), 2) AS diff_from_avg
FROM student
ORDER BY dept_id, gpa DESC;

-- 2.2: Calculate percentage of department total
SELECT first_name, dept_id, gpa,
       SUM(gpa) OVER (PARTITION BY dept_id) AS dept_total_gpa,
       ROUND(100.0 * gpa / SUM(gpa) OVER (PARTITION BY dept_id), 1) AS pct_of_dept_gpa
FROM student
ORDER BY dept_id, gpa DESC;

-- 2.3: Window with entire result set
SELECT first_name, gpa,
       AVG(gpa) OVER () AS overall_avg,
       MAX(gpa) OVER () AS overall_max,
       ROUND(gpa - AVG(gpa) OVER (), 2) AS diff_from_overall
FROM student
ORDER BY gpa DESC;

-- ============================================================================
-- PART 3: RUNNING TOTALS & MOVING AVERAGES
-- ============================================================================
-- Note: These examples use orders table from ecommerce.db
-- If using ATTACH DATABASE, prefix with 'ecommerce.orders'
--

-- 3.1: Running total of order amounts
SELECT order_id, order_date, total_amount,
       SUM(total_amount) OVER (
           ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM orders
ORDER BY order_date;

-- 3.2: Running total per customer
SELECT customer_id, order_date, total_amount,
       SUM(total_amount) OVER (
           PARTITION BY customer_id
           ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS customer_running_total
FROM orders
ORDER BY customer_id, order_date;

-- 3.3: 3-period moving average
SELECT order_id, order_date, total_amount,
       ROUND(AVG(total_amount) OVER (
           ORDER BY order_date
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS moving_avg_3
FROM orders
ORDER BY order_date;

-- 3.4: Running total of enrollments per semester
WITH enrollment_counts AS (
    SELECT semester, COUNT(*) AS cnt
    FROM enrollment
    GROUP BY semester
)
SELECT semester, cnt,
       SUM(cnt) OVER (ORDER BY semester) AS running_total
FROM enrollment_counts
ORDER BY semester;

-- ============================================================================
-- PART 4: LAG() and LEAD() - VALUE FUNCTIONS
-- ============================================================================

-- 4.1: Compare each order to previous order
SELECT order_id, order_date, total_amount,
       LAG(total_amount) OVER (ORDER BY order_date) AS prev_amount,
       total_amount - LAG(total_amount) OVER (ORDER BY order_date) AS change
FROM orders
ORDER BY order_date;

-- 4.2: Trend analysis with LAG
SELECT order_id, order_date, total_amount,
       LAG(total_amount) OVER (ORDER BY order_date) AS prev_amount,
       CASE
           WHEN total_amount > LAG(total_amount) OVER (ORDER BY order_date)
               THEN 'Up'
           WHEN total_amount < LAG(total_amount) OVER (ORDER BY order_date)
               THEN 'Down'
           ELSE 'Same'
       END AS trend
FROM orders
ORDER BY order_date;

-- 4.3: Days between consecutive orders
SELECT order_id, order_date,
       LAG(order_date) OVER (ORDER BY order_date) AS prev_date,
       JULIANDAY(order_date) - JULIANDAY(LAG(order_date) OVER (ORDER BY order_date))
           AS days_between
FROM orders
ORDER BY order_date;

-- 4.4: Compare with next value using LEAD
SELECT order_id, order_date, total_amount,
       LEAD(total_amount) OVER (ORDER BY order_date) AS next_amount,
       LEAD(total_amount) OVER (ORDER BY order_date) - total_amount AS change_to_next
FROM orders
ORDER BY order_date;

-- 4.5: Year-over-year comparison (if multiple years exist)
SELECT order_id, order_date, total_amount,
       LAG(order_date, 365) OVER (ORDER BY order_date) AS year_ago_date,
       LAG(total_amount, 365) OVER (ORDER BY order_date) AS year_ago_amount
FROM orders
ORDER BY order_date;

-- ============================================================================
-- PART 5: WINDOW FUNCTIONS + CTE COMBINED
-- ============================================================================

-- 5.1: Top 2 students per department
WITH ranked_students AS (
    SELECT s.first_name, s.last_name, d.dept_name, s.gpa,
           DENSE_RANK() OVER (
               PARTITION BY s.dept_id ORDER BY s.gpa DESC
           ) AS dept_rank
    FROM student s
    JOIN department d ON s.dept_id = d.dept_id
)
SELECT dept_name, first_name, last_name, gpa, dept_rank
FROM ranked_students
WHERE dept_rank <= 2
ORDER BY dept_name, dept_rank;

-- 5.2: Students above department average
WITH dept_stats AS (
    SELECT s.student_id, s.first_name, s.gpa, s.dept_id,
           AVG(s.gpa) OVER (PARTITION BY s.dept_id) AS dept_avg
    FROM student s
)
SELECT *
FROM dept_stats
WHERE gpa > dept_avg
ORDER BY dept_id, gpa DESC;

-- ============================================================================
-- PART 6: PIVOT OPERATIONS
-- ============================================================================
-- Note: These examples use tables from both university.db and ecommerce.db
-- The first exercises create new sample tables within the script
-- For existing tables, prefix with database alias: university.student, ecommerce.orders, etc.
--

-- 6.1: Setup: Create student grades table
CREATE TABLE IF NOT EXISTS student_grades (
    student_name TEXT,
    subject TEXT,
    grade TEXT,
    score INTEGER
);

DELETE FROM student_grades;
INSERT INTO student_grades VALUES
('Alice', 'Math', 'A', 95),
('Alice', 'Science', 'B', 85),
('Alice', 'English', 'A', 92),
('Bob', 'Math', 'B', 82),
('Bob', 'Science', 'A', 91),
('Bob', 'English', 'C', 74),
('Charlie', 'Math', 'A', 98),
('Charlie', 'Science', 'B', 88),
('Charlie', 'English', 'B', 85);

-- 6.2: Basic pivot - one row per student, one column per subject
SELECT student_name,
    MAX(CASE WHEN subject = 'Math' THEN grade END) AS math,
    MAX(CASE WHEN subject = 'Science' THEN grade END) AS science,
    MAX(CASE WHEN subject = 'English' THEN grade END) AS english
FROM student_grades
GROUP BY student_name
ORDER BY student_name;

-- 6.3: Pivot with multiple aggregations
SELECT student_name,
    SUM(CASE WHEN subject = 'Math' THEN score ELSE 0 END) AS math_score,
    SUM(CASE WHEN subject = 'Science' THEN score ELSE 0 END) AS science_score,
    SUM(CASE WHEN subject = 'English' THEN score ELSE 0 END) AS english_score,
    SUM(score) AS total_score,
    ROUND(AVG(score), 1) AS avg_score
FROM student_grades
GROUP BY student_name
ORDER BY total_score DESC;

-- 6.4: Pivot - calculate subject averages
SELECT 'Average' AS metric,
    ROUND(AVG(CASE WHEN subject = 'Math' THEN score END), 1) AS math,
    ROUND(AVG(CASE WHEN subject = 'Science' THEN score END), 1) AS science,
    ROUND(AVG(CASE WHEN subject = 'English' THEN score END), 1) AS english,
    ROUND(AVG(score), 1) AS overall
FROM student_grades;

-- 6.5: University enrollment pivot - students × courses
SELECT s.first_name,
    MAX(CASE WHEN c.course_name LIKE '%Database%' THEN e.grade END) AS database_grade,
    MAX(CASE WHEN c.course_name LIKE '%Algorithm%' THEN e.grade END) AS algo_grade,
    MAX(CASE WHEN c.course_name LIKE '%Calculus%' THEN e.grade END) AS calc_grade
FROM student s
LEFT JOIN enrollment e ON s.student_id = e.student_id
LEFT JOIN course c ON e.course_id = c.course_id
GROUP BY s.student_id, s.first_name
ORDER BY s.first_name;

-- 6.6: Department cross-tabulation by semester
SELECT d.dept_name,
    COUNT(CASE WHEN e.semester = 'Fall 2024' THEN 1 END) AS fall_2024,
    COUNT(CASE WHEN e.semester = 'Spring 2025' THEN 1 END) AS spring_2025,
    COUNT(*) AS total
FROM department d
JOIN student s ON d.dept_id = s.dept_id
JOIN enrollment e ON s.student_id = e.student_id
GROUP BY d.dept_id, d.dept_name
ORDER BY d.dept_name;

-- 6.7: GPA cross-tabulation by department
SELECT d.dept_name,
    COUNT(CASE WHEN s.gpa >= 3.5 THEN 1 END) AS 'A (3.5+)',
    COUNT(CASE WHEN s.gpa >= 3.0 AND s.gpa < 3.5 THEN 1 END) AS 'B (3.0-3.4)',
    COUNT(CASE WHEN s.gpa >= 2.0 AND s.gpa < 3.0 THEN 1 END) AS 'C (2.0-2.9)',
    COUNT(CASE WHEN s.gpa < 2.0 THEN 1 END) AS 'F (<2.0)',
    COUNT(*) AS total
FROM student s
JOIN department d ON s.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY d.dept_name;

-- ============================================================================
-- PART 7: UNPIVOT OPERATIONS
-- ============================================================================

-- 7.1: Setup: Create exam results table (wide format)
CREATE TABLE IF NOT EXISTS exam_results (
    student TEXT,
    midterm INTEGER,
    final_exam INTEGER,
    project INTEGER
);

DELETE FROM exam_results;
INSERT INTO exam_results VALUES ('Alice', 85, 92, 88);
INSERT INTO exam_results VALUES ('Bob', 78, 85, 90);
INSERT INTO exam_results VALUES ('Charlie', 92, 88, 95);

-- 7.2: Unpivot exam results to long format
SELECT student, 'Midterm' AS assessment, midterm AS score
FROM exam_results
UNION ALL
SELECT student, 'Final Exam', final_exam
FROM exam_results
UNION ALL
SELECT student, 'Project', project
FROM exam_results
ORDER BY student, assessment;

-- 7.3: Calculate statistics from unpivoted data
WITH unpivoted_exams AS (
    SELECT student, 'Midterm' AS assessment, midterm AS score
    FROM exam_results
    UNION ALL
    SELECT student, 'Final Exam', final_exam
    FROM exam_results
    UNION ALL
    SELECT student, 'Project', project
    FROM exam_results
)
SELECT student,
       AVG(score) AS avg_score,
       MAX(score) AS max_score,
       MIN(score) AS min_score
FROM unpivoted_exams
GROUP BY student
ORDER BY student;

-- 7.4: Setup: Create quarterly revenue table (wide format)
CREATE TABLE IF NOT EXISTS quarterly_rev (
    region TEXT,
    q1 REAL,
    q2 REAL,
    q3 REAL,
    q4 REAL
);

DELETE FROM quarterly_rev;
INSERT INTO quarterly_rev VALUES ('North', 50000, 55000, 60000, 70000);
INSERT INTO quarterly_rev VALUES ('South', 40000, 45000, 42000, 48000);
INSERT INTO quarterly_rev VALUES ('East', 35000, 38000, 40000, 45000);

-- 7.5: Unpivot quarterly sales to long format
SELECT region, 'Q1' AS quarter, q1 AS revenue FROM quarterly_rev
UNION ALL
SELECT region, 'Q2', q2 FROM quarterly_rev
UNION ALL
SELECT region, 'Q3', q3 FROM quarterly_rev
UNION ALL
SELECT region, 'Q4', q4 FROM quarterly_rev
ORDER BY region, quarter;

-- 7.6: Calculate annual totals from unpivoted data
WITH unpivoted AS (
    SELECT region, 'Q1' AS quarter, q1 AS revenue FROM quarterly_rev
    UNION ALL
    SELECT region, 'Q2', q2 FROM quarterly_rev
    UNION ALL
    SELECT region, 'Q3', q3 FROM quarterly_rev
    UNION ALL
    SELECT region, 'Q4', q4 FROM quarterly_rev
)
SELECT region,
       SUM(revenue) AS annual_total,
       ROUND(AVG(revenue), 0) AS quarterly_avg,
       MAX(revenue) AS max_quarter,
       MIN(revenue) AS min_quarter
FROM unpivoted
GROUP BY region
ORDER BY annual_total DESC;

-- ============================================================================
-- PART 8: COMBINED PIVOT + WINDOW FUNCTIONS
-- ============================================================================

-- 8.1: Setup: Create sales table
CREATE TABLE IF NOT EXISTS sales (
    sale_date TEXT,
    product TEXT,
    amount REAL
);

DELETE FROM sales;
INSERT INTO sales VALUES
('2025-01-15', 'Laptop', 1200),
('2025-01-20', 'Phone', 800),
('2025-02-10', 'Laptop', 1500),
('2025-02-15', 'Phone', 900),
('2025-02-20', 'Tablet', 600),
('2025-03-05', 'Laptop', 1300),
('2025-03-15', 'Phone', 850),
('2025-03-20', 'Tablet', 650);

-- 8.2: Combine pivot with running totals
WITH monthly AS (
    SELECT strftime('%Y-%m', sale_date) AS month,
           product,
           SUM(amount) AS revenue
    FROM sales
    GROUP BY strftime('%Y-%m', sale_date), product
)
SELECT month, product, revenue,
       SUM(revenue) OVER (
           PARTITION BY product ORDER BY month
       ) AS cumulative_revenue
FROM monthly
ORDER BY product, month;

-- 8.3: Monthly revenue pivot with cumulative
WITH monthly_totals AS (
    SELECT strftime('%Y-%m', sale_date) AS month,
           SUM(amount) AS total
    FROM sales
    GROUP BY strftime('%Y-%m', sale_date)
)
SELECT month, total,
       SUM(total) OVER (ORDER BY month) AS running_total
FROM monthly_totals
ORDER BY month;

-- 8.4: Product × Month pivot
SELECT product,
    SUM(CASE WHEN strftime('%m', sale_date) = '01' THEN amount ELSE 0 END) AS Jan,
    SUM(CASE WHEN strftime('%m', sale_date) = '02' THEN amount ELSE 0 END) AS Feb,
    SUM(CASE WHEN strftime('%m', sale_date) = '03' THEN amount ELSE 0 END) AS Mar,
    SUM(amount) AS total
FROM sales
GROUP BY product
ORDER BY total DESC;

.print '✅ Week 9 practice complete!'

-- ============================================================================
-- HOMEWORK EXERCISES
-- ============================================================================

-- Exercise 1: Window Functions
-- 1. Rank all students by GPA and show ROW_NUMBER, RANK, DENSE_RANK
-- 2. Find the top 3 students in each department
-- 3. Use NTILE(5) to create quintiles for GPA distribution

-- Exercise 2: Pivot
-- 1. Create a pivot showing student names as rows and subjects as columns with grades
-- 2. Calculate totals for each student across all subjects
-- 3. Add subject averages at the bottom

-- Exercise 3: Unpivot
-- 1. Create a wide table with different score columns
-- 2. Unpivot to (student, assessment, score) format
-- 3. Calculate each student's average from the unpivoted data

-- Exercise 4: Advanced
-- 1. Combine window functions with pivot to show running totals by department
-- 2. Create a report with both pivot and unpivot in the same query using CTEs
-- 3. Use CASE WHEN pivot with window functions for cumulative calculations
