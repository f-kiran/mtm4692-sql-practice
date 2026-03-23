-- ============================================================
-- MTM4692 Applied SQL — Week 5 Practice
-- Topic: Views
-- ============================================================
-- Run with: sqlite3 university.db < week05_practice.sql
-- ============================================================

PRAGMA foreign_keys = ON;
.headers on
.mode column

-- See all tables in the database
.schema

-- See student table structure
.schema student


-- ============================================================
-- SECTION 1: Basic Views
-- ============================================================

-- Student directory view
CREATE VIEW IF NOT EXISTS v_student_directory AS
SELECT first_name, last_name, email
FROM student
ORDER BY last_name, first_name;

SELECT * FROM v_student_directory;

-- Honor roll view
DROP VIEW IF EXISTS v_honor_roll; -- drop if exists to allow re-running script without errors
CREATE VIEW v_honor_roll AS
SELECT s.first_name, s.last_name, s.gpa, d.dept_name
FROM student s
JOIN department d ON s.dept_id = d.dept_id
WHERE s.gpa >= 3.5
ORDER BY s.gpa DESC;

SELECT * FROM v_honor_roll;

-- ============================================================
-- SECTION 2: Complex Multi-Table Views

-- it combines data from student, enrollment, course, department, and instructor tables
-- allows us to see a full transcript for each student, including course details and instructor names
-- so we can easily query for specific grades, courses, or departments without writing complex joins each time
-- ============================================================

-- Full transcript view
DROP VIEW IF EXISTS v_transcript;
CREATE VIEW v_transcript AS
SELECT s.student_id,
       s.first_name || ' ' || s.last_name AS student_name,
       d.dept_name,
       c.course_name, c.credits,
       e.grade, e.semester
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course c ON e.course_id = c.course_id
JOIN department d ON s.dept_id = d.dept_id;

SELECT * FROM v_transcript;

-- Query the view like a table
SELECT * FROM v_transcript WHERE grade = 'A';
SELECT * FROM v_transcript WHERE dept_name = 'Mathematical Engineering';

-- ============================================================
-- SECTION 3: Aggregation Views
-- ============================================================

-- Department statistics
DROP VIEW IF EXISTS v_dept_stats;
CREATE VIEW v_dept_stats AS
SELECT d.dept_name,
       COUNT(DISTINCT s.student_id) AS student_count,
       ROUND(AVG(s.gpa), 2) AS avg_gpa,
       COUNT(DISTINCT c.course_id) AS course_count,
       COUNT(DISTINCT i.instructor_id) AS instructor_count
FROM department d
LEFT JOIN student s ON d.dept_id = s.dept_id
LEFT JOIN course c ON d.dept_id = c.dept_id
LEFT JOIN instructor i ON d.dept_id = i.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM v_dept_stats;

-- Course enrollment summary
DROP VIEW IF EXISTS v_course_enrollment;
CREATE VIEW v_course_enrollment AS
SELECT  c.course_name,
       COUNT(e.student_id) AS enrolled_count,
       GROUP_CONCAT(e.grade) AS grades
FROM course c
LEFT JOIN enrollment e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name;

SELECT * FROM v_course_enrollment ORDER BY enrolled_count DESC;

-- ============================================================
-- SECTION 4: Security Views (Role-Based)
-- ============================================================

-- Public view (minimal info)
DROP VIEW IF EXISTS v_student_public;
CREATE VIEW v_student_public AS
SELECT student_id, first_name, last_name FROM student;

-- Advisor view (includes GPA)
DROP VIEW IF EXISTS v_student_advisor;
CREATE VIEW v_student_advisor AS
SELECT s.student_id, s.first_name, s.last_name,
       s.gpa, d.dept_name
FROM student s
JOIN department d ON s.dept_id = d.dept_id;

-- Registrar view (enrollment details)
DROP VIEW IF EXISTS v_registrar;
CREATE VIEW v_registrar AS
SELECT s.student_id, s.first_name, s.last_name,
       c.course_name,
       e.grade, e.semester
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course c ON e.course_id = c.course_id;

-- Test each view
.print '\n--- Public View ---'
SELECT * FROM v_student_public LIMIT 5;
.print '\n--- Advisor View ---'
SELECT * FROM v_student_advisor LIMIT 5;
.print '\n--- Registrar View ---'
SELECT * FROM v_registrar LIMIT 5;

-- ============================================================
-- SECTION 5: Views on Views (Nested)
-- ============================================================

-- Top performing students (view on v_honor_roll)
DROP VIEW IF EXISTS v_top_3;
CREATE VIEW v_top_3 AS
SELECT * FROM v_honor_roll LIMIT 3;

SELECT * FROM v_top_3;

-- ============================================================
-- SECTION 6 - 7 : INSTEAD OF Trigger and Update View Test
-- ============================================================

-- Simple single-table view → updatable
DROP VIEW IF EXISTS v_students_simple;
CREATE VIEW v_students_simple AS
SELECT student_id, first_name, last_name FROM student WHERE dept_id IS NOT NULL;

-- INSTEAD OF INSERT trigger for v_students_simple
DROP TRIGGER IF EXISTS tr_insert_students_simple;
CREATE TRIGGER tr_insert_students_simple
INSTEAD OF INSERT ON v_students_simple
BEGIN
    INSERT INTO student (student_id, first_name, last_name, email, dept_id)
    VALUES (NEW.student_id, NEW.first_name, NEW.last_name, NEW.first_name || '.' || NEW.last_name || '@university.edu', 1);
END;

-- INSTEAD OF UPDATE trigger for v_students_simple
DROP TRIGGER IF EXISTS tr_update_students_simple;
CREATE TRIGGER tr_update_students_simple
INSTEAD OF UPDATE ON v_students_simple
BEGIN
    UPDATE student SET first_name = NEW.first_name, last_name = NEW.last_name
    WHERE student_id = OLD.student_id;
END;

-- INSTEAD OF DELETE trigger for v_students_simple
DROP TRIGGER IF EXISTS tr_delete_students_simple;
CREATE TRIGGER tr_delete_students_simple
INSTEAD OF DELETE ON v_students_simple
BEGIN
    DELETE FROM student WHERE student_id = OLD.student_id;
END;

-- INSERT through view
INSERT INTO v_students_simple (student_id, first_name, last_name)
VALUES (NULL, 'ViewUser', 'TestUser');

-- Verify
SELECT * FROM v_students_simple WHERE first_name = 'ViewUser';

-- UPDATE through view - should change last_name to 'UpdatedName'
UPDATE v_students_simple SET last_name = 'UpdatedName' WHERE first_name = 'ViewUser';
SELECT * FROM v_students_simple WHERE first_name = 'ViewUser';


-- Verify
SELECT * FROM v_students_simple WHERE first_name = 'ViewUser';

-- DELETE through view
DELETE FROM v_students_simple WHERE first_name = 'ViewUser';


-- ============================================================
-- SECTION 8: Simulated Materialized View
-- Note: SQLite does not support true materialized views, but we can simulate it with a table
-- So it helps to store pre-aggregated data for performance, but we need to manually refresh it when underlying data changes
-- ============================================================

DROP TABLE IF EXISTS mv_student_summary;
CREATE TABLE mv_student_summary AS
SELECT d.dept_name,
       COUNT(*) AS student_count,
       ROUND(AVG(s.gpa), 2) AS avg_gpa,
       MAX(s.gpa) AS max_gpa
FROM student s
JOIN department d ON s.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

.print '\n--- Materialized View ---'
SELECT * FROM mv_student_summary;

-- To refresh: drop and recreate
DROP TABLE IF EXISTS mv_student_summary;


-- ============================================================
-- SECTION 9: List All Views
-- ============================================================

.print '\n--- All Views in Database ---'
SELECT name FROM sqlite_master WHERE type = 'view' ORDER BY name;

.print '\n--- View Definitions ---'
SELECT name, sql FROM sqlite_master WHERE type = 'view' ORDER BY name;

-- ============================================================
-- SECTION 10: Cleanup
-- ============================================================

-- Uncomment to remove all practice views:
-- DROP VIEW IF EXISTS v_student_directory;
-- DROP VIEW IF EXISTS v_honor_roll;
-- DROP VIEW IF EXISTS v_transcript;
-- DROP VIEW IF EXISTS v_dept_stats;
-- DROP VIEW IF EXISTS v_course_enrollment;
-- DROP VIEW IF EXISTS v_student_public;
-- DROP VIEW IF EXISTS v_student_advisor;
-- DROP VIEW IF EXISTS v_registrar;
-- DROP VIEW IF EXISTS v_top_3;
-- DROP VIEW IF EXISTS v_students_simple;
-- DROP VIEW IF EXISTS v_student_dept;
-- DROP TRIGGER IF EXISTS tr_insert_student_dept;
-- DROP TRIGGER IF EXISTS tr_insert_students_simple;
-- DROP TRIGGER IF EXISTS tr_update_students_simple;
-- DROP TRIGGER IF EXISTS tr_delete_students_simple;

.print '✅ Week 5 practice complete!'
