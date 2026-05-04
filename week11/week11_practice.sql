-- ============================================================
-- MTM4692 Applied SQL — Week 11 Practice
-- Topic: Functions & Stored Procedures — SQLite Equivalents
-- ============================================================
-- Run with: sqlite3 university.db < week11_practice.sql
-- ============================================================

PRAGMA foreign_keys = ON;
.headers on
.mode column

-- ============================================================
-- SECTION 1: View as Reusable "Function" — Letter Grade
-- ============================================================

.print '\n=== View as Function: Letter Grade ==='

DROP VIEW IF EXISTS student_grades;
CREATE VIEW student_grades AS
SELECT student_id, first_name, last_name, gpa,
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
        WHEN gpa >= 3.5 THEN 'Honor Roll'
        WHEN gpa >= 2.0 THEN 'Good Standing'
        ELSE 'Probation'
    END AS standing
FROM student;

-- Use it like a function call
SELECT * FROM student_grades ORDER BY gpa DESC;

.print '\n=== Filter by Grade ==='
SELECT * FROM student_grades WHERE letter_grade = 'A';

-- ============================================================
-- SECTION 2: View as "Function" — Scholarship Calculator
-- ============================================================

.print '\n=== View as Function: Scholarship ==='

DROP VIEW IF EXISTS student_scholarship;
CREATE VIEW student_scholarship AS
SELECT student_id, first_name, last_name, gpa, dept_id,
    CASE
        WHEN gpa >= 3.8 THEN 5000
        WHEN gpa >= 3.5 THEN 3000
        WHEN gpa >= 3.0 THEN 1000
        ELSE 0
    END AS scholarship_amount,
    CASE
        WHEN gpa >= 3.8 THEN 'Full Merit'
        WHEN gpa >= 3.5 THEN 'Partial Merit'
        WHEN gpa >= 3.0 THEN 'Encouragement'
        ELSE 'None'
    END AS scholarship_type
FROM student;

SELECT * FROM student_scholarship
WHERE scholarship_amount > 0
ORDER BY scholarship_amount DESC;

-- Total scholarship budget
.print '\n=== Total Scholarship Budget ==='
SELECT
    scholarship_type,
    COUNT(*) AS recipients,
    SUM(scholarship_amount) AS total_cost,
    ROUND(AVG(gpa), 2) AS avg_gpa
FROM student_scholarship
WHERE scholarship_amount > 0
GROUP BY scholarship_type
ORDER BY total_cost DESC;

-- ============================================================
-- SECTION 3: CTE as "Stored Procedure" — Department Stats
-- ============================================================

.print '\n=== CTE as Procedure: Department Stats ==='

-- Equivalent of: CALL get_dept_stats(dept_id, @count, @avg, @max)
WITH dept_stats AS (
    SELECT
        d.dept_id,
        d.dept_name,
        COUNT(s.student_id) AS student_count,
        ROUND(AVG(s.gpa), 2) AS avg_gpa,
        ROUND(MAX(s.gpa), 2) AS max_gpa,
        ROUND(MIN(s.gpa), 2) AS min_gpa
    FROM department d
    LEFT JOIN student s ON d.dept_id = s.dept_id
    GROUP BY d.dept_id, d.dept_name
)
SELECT * FROM dept_stats ORDER BY avg_gpa DESC;

-- ============================================================
-- SECTION 4: CTE as "Procedure" — Comprehensive Report
-- ============================================================

.print '\n=== Multi-Output Report (like a procedure with result sets) ==='

WITH
    -- "Variable" block
    overall AS (
        SELECT AVG(gpa) AS avg_gpa, COUNT(*) AS total FROM student
    ),
    -- Per-department stats
    dept_summary AS (
        SELECT d.dept_name,
               COUNT(s.student_id) AS students,
               ROUND(AVG(s.gpa), 2) AS avg_gpa,
               MAX(s.gpa) AS top_gpa
        FROM department d
        LEFT JOIN student s ON d.dept_id = s.dept_id
        GROUP BY d.dept_id, d.dept_name
    ),
    -- Top student per department
    ranked AS (
        SELECT s.first_name, s.last_name, s.gpa, d.dept_name,
               ROW_NUMBER() OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS rn
        FROM student s
        JOIN department d ON s.dept_id = d.dept_id
    )
SELECT ds.dept_name,
       ds.students,
       ds.avg_gpa AS dept_avg,
       ROUND(o.avg_gpa, 2) AS overall_avg,
       r.first_name || ' ' || r.last_name AS top_student,
       r.gpa AS top_gpa
FROM dept_summary ds
CROSS JOIN overall o
LEFT JOIN ranked r ON ds.dept_name = r.dept_name AND r.rn = 1
ORDER BY ds.avg_gpa DESC;

-- ============================================================
-- SECTION 5: Weighted Grade Calculator (Function equivalent)
-- ============================================================

.print '\n=== Weighted Grade Calculator ==='

-- Simulating: calculate_final_grade(midterm, final, project)
-- Midterm 30%, Final 30%, Project 40%

DROP VIEW IF EXISTS student_final_grades;
CREATE VIEW student_final_grades AS
WITH sample_grades AS (
    SELECT student_id, first_name, last_name,
           -- Simulate exam scores from GPA (for demo)
           ROUND(gpa * 25, 1) AS midterm,     -- 0-100 scale
           ROUND(gpa * 24, 1) AS final_exam,  -- 0-100 scale
           ROUND(gpa * 23, 1) AS project      -- 0-100 scale
    FROM student
)
SELECT student_id, first_name, last_name,
       midterm, final_exam, project,
       ROUND(midterm * 0.30 + final_exam * 0.30 + project * 0.40, 2)
           AS weighted_avg,
       CASE
           WHEN (midterm * 0.30 + final_exam * 0.30 + project * 0.40) >= 90 THEN 'AA'
           WHEN (midterm * 0.30 + final_exam * 0.30 + project * 0.40) >= 85 THEN 'BA'
           WHEN (midterm * 0.30 + final_exam * 0.30 + project * 0.40) >= 80 THEN 'BB'
           WHEN (midterm * 0.30 + final_exam * 0.30 + project * 0.40) >= 75 THEN 'CB'
           WHEN (midterm * 0.30 + final_exam * 0.30 + project * 0.40) >= 65 THEN 'CC'
           WHEN (midterm * 0.30 + final_exam * 0.30 + project * 0.40) >= 55 THEN 'DC'
           WHEN (midterm * 0.30 + final_exam * 0.30 + project * 0.40) >= 50 THEN 'DD'
           ELSE 'FF'
       END AS letter
FROM sample_grades;

SELECT * FROM student_final_grades ORDER BY weighted_avg DESC;

-- ============================================================
-- SECTION 6: Trigger as "Procedure" — Enrollment Validation
-- ============================================================

.print '\n=== Trigger as Procedure: Enrollment Guard ==='

-- Create enrollment table if not exists
CREATE TABLE IF NOT EXISTS enrollment (
    enrollment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    enroll_date TEXT DEFAULT (date('now')),
    grade TEXT,
    FOREIGN KEY (student_id) REFERENCES student(student_id),
    FOREIGN KEY (course_id) REFERENCES course(course_id)
);

-- Prevent duplicate enrollments (like a validation procedure)
DROP TRIGGER IF EXISTS prevent_duplicate_enrollment;
CREATE TRIGGER prevent_duplicate_enrollment
    BEFORE INSERT ON enrollment
BEGIN
    SELECT CASE
        WHEN (SELECT COUNT(*) FROM enrollment
              WHERE student_id = NEW.student_id
                AND course_id = NEW.course_id) > 0
        THEN RAISE(ABORT, 'ERROR: Student already enrolled in this course')
    END;
END;

-- GPA validation trigger (like a CHECK procedure)
DROP TRIGGER IF EXISTS validate_gpa;
CREATE TRIGGER validate_gpa
    BEFORE INSERT ON student
BEGIN
    SELECT CASE
        WHEN NEW.gpa < 0.0 OR NEW.gpa > 4.0
        THEN RAISE(ABORT, 'ERROR: GPA must be between 0.0 and 4.0')
    END;
END;

DROP TRIGGER IF EXISTS validate_gpa_update;
CREATE TRIGGER validate_gpa_update
    BEFORE UPDATE OF gpa ON student
BEGIN
    SELECT CASE
        WHEN NEW.gpa < 0.0 OR NEW.gpa > 4.0
        THEN RAISE(ABORT, 'ERROR: GPA must be between 0.0 and 4.0')
    END;
END;

.print 'Triggers created successfully'

-- ============================================================
-- SECTION 7: Audit Log (Procedure-like automation)
-- ============================================================

.print '\n=== Audit Log System ==='

CREATE TABLE IF NOT EXISTS audit_log (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    action TEXT NOT NULL,
    old_values TEXT,
    new_values TEXT,
    timestamp TEXT DEFAULT (datetime('now'))
);

-- Audit trigger for student updates
DROP TRIGGER IF EXISTS audit_student_update;
CREATE TRIGGER audit_student_update
    AFTER UPDATE ON student
BEGIN
    INSERT INTO audit_log (table_name, action, old_values, new_values)
    VALUES (
        'student',
        'UPDATE',
        'name=' || OLD.first_name || ' ' || OLD.last_name || ', gpa=' || OLD.gpa,
        'name=' || NEW.first_name || ' ' || NEW.last_name || ', gpa=' || NEW.gpa
    );
END;

-- Test: update a student
UPDATE student SET gpa = gpa WHERE student_id = (SELECT MIN(student_id) FROM student);

.print '\n=== Audit Log Entries ==='
SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 5;

-- ============================================================
-- SECTION 8: Discount View (Function equivalent for E-commerce)
-- ============================================================

.print '\n=== E-commerce Discount View ==='

-- This simulates: calc_discount(total, membership_type)
-- and calc_final_total(order_id)

DROP VIEW IF EXISTS order_summary;
CREATE VIEW order_summary AS
WITH order_totals AS (
    SELECT o.order_id,
           c.first_name || ' ' || c.last_name AS customer,
           SUM(oi.quantity * oi.unit_price) AS subtotal
    FROM orders o
    JOIN customer c ON o.customer_id = c.customer_id
    JOIN order_item oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, c.first_name, c.last_name
)
SELECT order_id, customer, subtotal,
    -- Tiered discount (like a function)
    CASE
        WHEN subtotal >= 500 THEN 0.20
        WHEN subtotal >= 200 THEN 0.10
        WHEN subtotal >= 100 THEN 0.05
        ELSE 0.00
    END AS discount_rate,
    ROUND(subtotal * CASE
        WHEN subtotal >= 500 THEN 0.20
        WHEN subtotal >= 200 THEN 0.10
        WHEN subtotal >= 100 THEN 0.05
        ELSE 0.00
    END, 2) AS discount_amount,
    ROUND(subtotal * (1 - CASE
        WHEN subtotal >= 500 THEN 0.20
        WHEN subtotal >= 200 THEN 0.10
        WHEN subtotal >= 100 THEN 0.05
        ELSE 0.00
    END), 2) AS final_total
FROM order_totals;

SELECT * FROM order_summary ORDER BY subtotal DESC;

-- ============================================================
-- SECTION 9: DETERMINISTIC vs NOT DETERMINISTIC Concepts
-- ============================================================

.print '\n=== DETERMINISTIC: Pure Computations ==='

-- These are DETERMINISTIC (same input → same output)
SELECT
    3.14159 * 5 * 5 AS circle_area_r5,
    (100.0 - 32) * 5.0 / 9.0 AS fahrenheit_100_to_celsius,
    ROUND(75.0 * 0.30 + 80.0 * 0.30 + 90.0 * 0.40, 2) AS weighted_grade;

-- These are NOT DETERMINISTIC (depend on current data)
.print '\n=== NOT DETERMINISTIC: Data-Dependent ==='
SELECT date('now') AS today,
       (SELECT COUNT(*) FROM student) AS student_count,
       (SELECT AVG(gpa) FROM student) AS current_avg;

-- ============================================================
-- SECTION 10: Comprehensive Exercise
-- ============================================================

.print '\n=== Comprehensive: Student Report Card System ==='

-- Simulates a stored procedure that generates a full report card
WITH
    -- "Parameters"
    params AS (SELECT 1 AS target_dept_id),
    -- "Variables" calculated once
    class_stats AS (
        SELECT
            ROUND(AVG(gpa), 2) AS class_avg,
            ROUND(MIN(gpa), 2) AS class_min,
            ROUND(MAX(gpa), 2) AS class_max,
            COUNT(*) AS class_total
        FROM student
    ),
    -- "Logic" applied to each student
    report_cards AS (
        SELECT
            s.student_id,
            s.first_name || ' ' || s.last_name AS student_name,
            d.dept_name,
            s.gpa,
            -- Grade function
            CASE
                WHEN s.gpa >= 3.7 THEN 'A'
                WHEN s.gpa >= 3.3 THEN 'B+'
                WHEN s.gpa >= 3.0 THEN 'B'
                WHEN s.gpa >= 2.0 THEN 'C'
                ELSE 'F'
            END AS grade,
            -- Scholarship function
            CASE
                WHEN s.gpa >= 3.8 THEN 5000
                WHEN s.gpa >= 3.5 THEN 3000
                WHEN s.gpa >= 3.0 THEN 1000
                ELSE 0
            END AS scholarship,
            -- Rank "variable"
            RANK() OVER (ORDER BY s.gpa DESC) AS class_rank,
            RANK() OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS dept_rank,
            -- Percentile
            ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY s.gpa), 1) AS percentile
        FROM student s
        JOIN department d ON s.dept_id = d.dept_id
    )
SELECT
    rc.class_rank AS '#',
    rc.student_name,
    rc.dept_name,
    rc.gpa,
    rc.grade,
    rc.scholarship AS '$',
    rc.dept_rank AS 'Dept#',
    rc.percentile || '%' AS pctl,
    CASE WHEN rc.gpa > cs.class_avg THEN '↑' ELSE '↓' END AS vs_avg
FROM report_cards rc
CROSS JOIN class_stats cs
ORDER BY rc.class_rank;

-- Show class statistics
.print '\n=== Class Statistics ==='
SELECT * FROM (
    SELECT 'Average' AS metric, ROUND(AVG(gpa), 2) AS value FROM student
    UNION ALL
    SELECT 'Minimum', ROUND(MIN(gpa), 2) FROM student
    UNION ALL
    SELECT 'Maximum', ROUND(MAX(gpa), 2) FROM student
    UNION ALL
    SELECT 'Total Students', COUNT(*) FROM student
    UNION ALL
    SELECT 'Scholarship Recipients',
        COUNT(CASE WHEN gpa >= 3.0 THEN 1 END) FROM student
    UNION ALL
    SELECT 'Total Scholarship $',
        SUM(CASE
            WHEN gpa >= 3.8 THEN 5000
            WHEN gpa >= 3.5 THEN 3000
            WHEN gpa >= 3.0 THEN 1000
            ELSE 0
        END) FROM student
);

-- Cleanup
DROP VIEW IF EXISTS student_grades;
DROP VIEW IF EXISTS student_scholarship;
DROP VIEW IF EXISTS student_final_grades;
DROP VIEW IF EXISTS order_summary;
DROP TABLE IF EXISTS audit_log;

.print '\n✅ Week 11 practice complete!'
