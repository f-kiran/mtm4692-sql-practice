-- ============================================================
-- MTM4692 Applied SQL — Week 5 Practice
-- Topic: Views
-- ============================================================
-- Run with: sqlite3 university.db < week05_practice.sql
-- ============================================================

PRAGMA foreign_keys = ON;
.headers on
.mode column

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
DROP VIEW IF EXISTS v_honor_roll;
CREATE VIEW v_honor_roll AS
SELECT s.first_name, s.last_name, s.gpa, d.dept_name
FROM student s
JOIN department d ON s.dept_id = d.dept_id
WHERE s.gpa >= 3.5
ORDER BY s.gpa DESC;

SELECT * FROM v_honor_roll;

-- ============================================================
-- SECTION 2: Complex Multi-Table Views
-- ============================================================

-- Full transcript view
DROP VIEW IF EXISTS v_transcript;
CREATE VIEW v_transcript AS
SELECT s.student_id,
       s.first_name || ' ' || s.last_name AS student_name,
       d.dept_name,
       c.course_code, c.course_name, c.credits,
       e.grade, e.semester,
       COALESCE(i.first_name || ' ' || i.last_name, 'TBA') AS instructor_name
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course c ON e.course_id = c.course_id
JOIN department d ON s.dept_id = d.dept_id
LEFT JOIN instructor i ON c.instructor_id = i.instructor_id;

SELECT * FROM v_transcript;

-- Query the view like a table
SELECT * FROM v_transcript WHERE grade = 'A';
SELECT * FROM v_transcript WHERE dept_name = 'Computer Science';

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
SELECT c.course_code, c.course_name,
       COUNT(e.student_id) AS enrolled_count,
       GROUP_CONCAT(e.grade) AS grades
FROM course c
LEFT JOIN enrollment e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_code, c.course_name;

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
       c.course_code, c.course_name,
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
-- SECTION 6: Updatable View Test
-- ============================================================

-- Simple single-table view → updatable
DROP VIEW IF EXISTS v_students_simple;
CREATE VIEW v_students_simple AS
SELECT student_id, first_name, last_name, gpa FROM student;

-- INSERT through view
INSERT INTO v_students_simple (first_name, last_name, gpa)
VALUES ('View', 'TestUser', 3.0);

-- Verify
SELECT * FROM v_students_simple WHERE first_name = 'View';

-- UPDATE through view
UPDATE v_students_simple SET gpa = 3.5 WHERE first_name = 'View';
SELECT * FROM v_students_simple WHERE first_name = 'View';

-- DELETE through view
DELETE FROM v_students_simple WHERE first_name = 'View';

-- ============================================================
-- SECTION 7: INSTEAD OF Trigger
-- ============================================================

DROP VIEW IF EXISTS v_student_dept;
CREATE VIEW v_student_dept AS
SELECT s.student_id, s.first_name, s.last_name, d.dept_name
FROM student s
JOIN department d ON s.dept_id = d.dept_id;

-- INSTEAD OF INSERT trigger
DROP TRIGGER IF EXISTS tr_insert_student_dept;
CREATE TRIGGER tr_insert_student_dept
INSTEAD OF INSERT ON v_student_dept
BEGIN
    INSERT INTO student (first_name, last_name, dept_id)
    VALUES (
        NEW.first_name, NEW.last_name,
        (SELECT dept_id FROM department WHERE dept_name = NEW.dept_name)
    );
END;

-- Test: insert through multi-table view
INSERT INTO v_student_dept (first_name, last_name, dept_name)
VALUES ('Trigger', 'Test', 'Computer Science');

-- Verify
SELECT * FROM v_student_dept WHERE first_name = 'Trigger';

-- Cleanup
DELETE FROM student WHERE first_name = 'Trigger';

-- ============================================================
-- SECTION 8: Simulated Materialized View
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

.print '✅ Week 5 practice complete!'
