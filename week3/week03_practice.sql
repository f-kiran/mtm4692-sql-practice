-- ============================================================
-- MTM4692 Applied SQL — Week 3: Advanced Queries
-- Practice Code File
-- ============================================================
-- This file uses both the university and ecommerce databases.
--
-- PART A (University):
--   sqlite3 university.db < week03_practice.sql
--
-- PART B (E-Commerce):
--   sqlite3 ecommerce.db  (then paste Part B queries)
--
-- Or run interactively:
--   sqlite3 university.db
--   .read week03_practice.sql
-- ============================================================

-- ============================================================
-- SETUP
-- ============================================================
.headers on
.mode column
PRAGMA foreign_keys = ON;

-- ============================================================
-- REBUILD UNIVERSITY DATABASE (if needed)
-- ============================================================
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS enrollment;
DROP TABLE IF EXISTS student;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS instructor;
DROP TABLE IF EXISTS department;

CREATE TABLE department (
    dept_id    INTEGER PRIMARY KEY,
    dept_name  TEXT    NOT NULL,
    building   TEXT,
    budget     REAL    DEFAULT 0.0
);

CREATE TABLE student (
    student_id  INTEGER PRIMARY KEY,
    first_name  TEXT    NOT NULL,
    last_name   TEXT    NOT NULL,
    email       TEXT    UNIQUE NOT NULL,
    birth_date  TEXT,
    gpa         REAL    DEFAULT 0.0 CHECK (gpa >= 0.0 AND gpa <= 4.0),
    dept_id     INTEGER,
    FOREIGN KEY (dept_id) REFERENCES department(dept_id)
);

CREATE TABLE course (
    course_id    INTEGER PRIMARY KEY,
    course_name  TEXT NOT NULL,
    credits      INTEGER DEFAULT 3 CHECK (credits > 0 AND credits <= 6),
    dept_id      INTEGER,
    FOREIGN KEY (dept_id) REFERENCES department(dept_id)
);

CREATE TABLE instructor (
    instructor_id  INTEGER PRIMARY KEY,
    first_name     TEXT NOT NULL,
    last_name      TEXT NOT NULL,
    email          TEXT UNIQUE,
    dept_id        INTEGER,
    FOREIGN KEY (dept_id) REFERENCES department(dept_id)
);

CREATE TABLE enrollment (
    enrollment_id  INTEGER PRIMARY KEY,
    student_id     INTEGER NOT NULL,
    course_id      INTEGER NOT NULL,
    semester       TEXT NOT NULL,
    grade          TEXT CHECK (grade IN ('A','B','C','D','F') OR grade IS NULL),
    FOREIGN KEY (student_id) REFERENCES student(student_id),
    FOREIGN KEY (course_id)  REFERENCES course(course_id),
    UNIQUE(student_id, course_id, semester)
);

-- ============================================================
-- INSERT DATA
-- ============================================================

INSERT INTO department (dept_name, building, budget) VALUES
    ('Mathematical Engineering', 'B Block', 500000.00),
    ('Computer Engineering', 'A Block', 750000.00),
    ('Electrical Engineering', 'C Block', 600000.00),
    ('Civil Engineering', 'D Block', 550000.00),
    ('Physics', 'E Block', 400000.00),
    ('Chemistry', 'F Block', 350000.00);  -- No students!

INSERT INTO student (first_name, last_name, email, birth_date, gpa, dept_id) VALUES
    ('Alice',  'Yılmaz',  'alice@ytu.edu.tr',  '2002-05-15', 3.75, 1),
    ('Bob',    'Kaya',    'bob@ytu.edu.tr',    '2001-11-20', 3.20, 2),
    ('Carol',  'Demir',   'carol@ytu.edu.tr',  '2003-01-10', 3.90, 1),
    ('David',  'Çelik',   'david@ytu.edu.tr',  '2002-07-22', 2.85, 3),
    ('Elif',   'Arslan',  'elif@ytu.edu.tr',   '2001-09-03', 3.50, 2),
    ('Fatma',  'Öztürk',  'fatma@ytu.edu.tr',  '2003-03-18', 3.65, 4),
    ('Gökhan', 'Aydın',   'gokhan@ytu.edu.tr', '2002-12-01', 2.95, 3),
    ('Hakan',  'Şahin',   'hakan@ytu.edu.tr',  '2001-06-14', 3.10, 5),
    ('Irem',   'Koç',     'irem@ytu.edu.tr',   '2003-08-25', 3.55, 1),
    ('Kemal',  'Yıldız',  'kemal@ytu.edu.tr',  '2002-04-09', 2.70, 4),
    ('Lale',   'Güneş',   'lale@ytu.edu.tr',   '2003-06-30', 3.40, NULL),  -- No dept!
    ('Murat',  'Aksoy',   'murat@ytu.edu.tr',  '2001-02-14', 3.80, 2);

INSERT INTO course (course_name, credits, dept_id) VALUES
    ('Applied SQL', 3, 1),
    ('Data Structures', 4, 2),
    ('Linear Algebra', 3, 1),
    ('Circuit Theory', 4, 3),
    ('Mechanics', 3, 4),
    ('Quantum Physics', 3, 5),
    ('Algorithms', 4, 2),
    ('Differential Equations', 3, 1),
    ('Organic Chemistry', 3, 6),        -- Course exists but no enrollments
    ('Machine Learning', 4, 2);         -- Course exists but no enrollments

INSERT INTO instructor (first_name, last_name, email, dept_id) VALUES
    ('Fettah', 'Kiran',  'fkiran@ytu.edu.tr', 1),
    ('Ayşe',   'Demir',  'ayse.d@ytu.edu.tr', 2),
    ('Mehmet', 'Yılmaz', 'mehmet.y@ytu.edu.tr', 3),
    ('Zeynep', 'Kara',   'zeynep.k@ytu.edu.tr', 1),
    ('Ali',    'Çetin',  'ali.c@ytu.edu.tr', 5);

INSERT INTO enrollment (student_id, course_id, semester, grade) VALUES
    (1, 1, '2025-Spring', 'A'),   -- Alice: Applied SQL
    (1, 3, '2025-Spring', 'A'),   -- Alice: Linear Algebra
    (1, 8, '2025-Spring', 'B'),   -- Alice: Diff Equations
    (2, 1, '2025-Spring', 'B'),   -- Bob: Applied SQL
    (2, 2, '2025-Spring', 'A'),   -- Bob: Data Structures
    (3, 1, '2025-Spring', 'A'),   -- Carol: Applied SQL
    (3, 3, '2025-Spring', 'A'),   -- Carol: Linear Algebra
    (4, 4, '2025-Spring', 'C'),   -- David: Circuit Theory
    (5, 2, '2025-Spring', 'B'),   -- Elif: Data Structures
    (5, 7, '2025-Spring', 'A'),   -- Elif: Algorithms
    (6, 5, '2025-Spring', 'A'),   -- Fatma: Mechanics
    (7, 4, '2025-Spring', 'B'),   -- Gökhan: Circuit Theory
    (8, 6, '2025-Spring', 'C'),   -- Hakan: Quantum Physics
    (9, 1, '2025-Spring', 'A'),   -- Irem: Applied SQL
    (9, 8, '2025-Spring', 'B'),   -- Irem: Diff Equations
    (10, 5, '2025-Spring', 'D'),  -- Kemal: Mechanics
    (12, 1, '2025-Spring', 'A'),  -- Murat: Applied SQL
    (12, 2, '2025-Spring', 'A'),  -- Murat: Data Structures
    (12, 7, '2025-Spring', 'B');  -- Murat: Algorithms

-- Lale (student 11) has NO enrollments

-- ============================================================
-- PART A: INNER JOIN EXERCISES
-- ============================================================

SELECT '============================';
SELECT 'PART A: INNER JOIN';
SELECT '============================';

-- A1: Students with their department names
SELECT '--- A1: Students + Departments ---';
SELECT s.first_name, s.last_name, d.dept_name
FROM   student s
INNER JOIN department d ON s.dept_id = d.dept_id
ORDER BY d.dept_name, s.last_name;

-- A2: Enrollments with student and course names
SELECT '--- A2: Enrollment Details ---';
SELECT s.first_name || ' ' || s.last_name AS student,
       c.course_name,
       e.grade,
       e.semester
FROM   enrollment e
JOIN   student s ON e.student_id = s.student_id
JOIN   course c  ON e.course_id  = c.course_id
ORDER BY s.last_name, c.course_name;

-- A3: Three-table JOIN — students, courses, departments
SELECT '--- A3: Student-Course-Department ---';
SELECT s.first_name,
       c.course_name,
       d.dept_name AS student_dept
FROM   student s
JOIN   department d ON s.dept_id = d.dept_id
JOIN   enrollment e ON s.student_id = e.student_id
JOIN   course c     ON e.course_id = c.course_id
ORDER BY s.first_name;

-- ============================================================
-- PART B: LEFT JOIN EXERCISES
-- ============================================================

SELECT '';
SELECT '============================';
SELECT 'PART B: LEFT JOIN';
SELECT '============================';

-- B1: All students including those without a department
SELECT '--- B1: All Students (with NULL departments) ---';
SELECT s.first_name, s.last_name,
       COALESCE(d.dept_name, '⚠️ No Department') AS department
FROM   student s
LEFT JOIN department d ON s.dept_id = d.dept_id
ORDER BY department;

-- B2: All departments with student count (including empty ones)
SELECT '--- B2: Students per Department (all depts) ---';
SELECT d.dept_name,
       COUNT(s.student_id) AS num_students
FROM   department d
LEFT JOIN student s ON d.dept_id = s.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY num_students DESC;

-- B3: Anti-Join — Students with NO enrollments
SELECT '--- B3: Students Not Enrolled in Any Course ---';
SELECT s.first_name, s.last_name
FROM   student s
LEFT JOIN enrollment e ON s.student_id = e.student_id
WHERE  e.enrollment_id IS NULL;

-- B4: Anti-Join — Courses with NO enrollments
SELECT '--- B4: Courses with No Students ---';
SELECT c.course_name, c.credits
FROM   course c
LEFT JOIN enrollment e ON c.course_id = e.course_id
WHERE  e.enrollment_id IS NULL;

-- B5: Departments with NO students
SELECT '--- B5: Departments with No Students ---';
SELECT d.dept_name
FROM   department d
LEFT JOIN student s ON d.dept_id = s.dept_id
WHERE  s.student_id IS NULL;

-- ============================================================
-- PART C: SELF JOIN
-- ============================================================

SELECT '';
SELECT '============================';
SELECT 'PART C: SELF JOIN';
SELECT '============================';

-- Create employee hierarchy table
CREATE TABLE IF NOT EXISTS employee (
    emp_id      INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    position    TEXT,
    manager_id  INTEGER,
    salary      REAL,
    dept_id     INTEGER,
    FOREIGN KEY (manager_id) REFERENCES employee(emp_id),
    FOREIGN KEY (dept_id) REFERENCES department(dept_id)
);

DELETE FROM employee;
INSERT INTO employee VALUES
    (1, 'Ali Yılmaz',    'CEO',              NULL, 150000, NULL),
    (2, 'Ayşe Kara',     'VP Engineering',   1,   120000, 2),
    (3, 'Mehmet Demir',  'VP Academics',      1,   110000, 1),
    (4, 'Zeynep Çelik',  'Sr. Developer',    2,    90000, 2),
    (5, 'Can Öz',        'Developer',         2,    75000, 2),
    (6, 'Deniz Ak',      'Professor',         3,    85000, 1),
    (7, 'Ece Tan',       'Jr. Developer',     4,    65000, 2),
    (8, 'Fatih Kaya',    'Asst. Professor',   3,    70000, 1);

-- C1: Employee with manager name
SELECT '--- C1: Employee-Manager Hierarchy ---';
SELECT e.name AS employee,
       e.position,
       COALESCE(m.name, '(Top Level)') AS manager
FROM   employee e
LEFT JOIN employee m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;

-- C2: Employees who earn more than their manager (!)
SELECT '--- C2: Employees Earning More Than Their Manager ---';
SELECT e.name AS employee,
       e.salary AS emp_salary,
       m.name AS manager,
       m.salary AS mgr_salary,
       ROUND(e.salary - m.salary, 2) AS salary_diff
FROM   employee e
JOIN   employee m ON e.manager_id = m.emp_id
WHERE  e.salary > m.salary;

-- C3: Count direct reports
SELECT '--- C3: Direct Reports per Manager ---';
SELECT m.name AS manager,
       m.position,
       COUNT(e.emp_id) AS direct_reports
FROM   employee m
LEFT JOIN employee e ON e.manager_id = m.emp_id
GROUP BY m.emp_id, m.name, m.position
ORDER BY direct_reports DESC;

-- ============================================================
-- PART D: GROUP BY & HAVING
-- ============================================================

SELECT '';
SELECT '============================';
SELECT 'PART D: GROUP BY & HAVING';
SELECT '============================';

-- D1: Students per department
SELECT '--- D1: Students per Department ---';
SELECT d.dept_name,
       COUNT(*) AS num_students,
       ROUND(AVG(s.gpa), 2) AS avg_gpa,
       MIN(s.gpa) AS min_gpa,
       MAX(s.gpa) AS max_gpa
FROM   student s
JOIN   department d ON s.dept_id = d.dept_id
GROUP BY d.dept_id
ORDER BY avg_gpa DESC;

-- D2: Enrollments per course
SELECT '--- D2: Enrollments per Course ---';
SELECT c.course_name,
       COUNT(*) AS enrollment_count,
       GROUP_CONCAT(e.grade, ', ') AS grades
FROM   enrollment e
JOIN   course c ON e.course_id = c.course_id
GROUP BY c.course_id
ORDER BY enrollment_count DESC;

-- D3: HAVING — Courses with 3+ enrollments
SELECT '--- D3: Popular Courses (3+ students) ---';
SELECT c.course_name,
       COUNT(*) AS num_students
FROM   enrollment e
JOIN   course c ON e.course_id = c.course_id
GROUP BY c.course_id
HAVING COUNT(*) >= 3
ORDER BY num_students DESC;

-- D4: Grade distribution
SELECT '--- D4: Grade Distribution ---';
SELECT grade,
       COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM enrollment), 1) || '%' AS percentage
FROM   enrollment
WHERE  grade IS NOT NULL
GROUP BY grade
ORDER BY grade;

-- D5: Students with more than 2 courses
SELECT '--- D5: Students Enrolled in 2+ Courses ---';
SELECT s.first_name || ' ' || s.last_name AS student,
       COUNT(*) AS num_courses,
       GROUP_CONCAT(c.course_name, ', ') AS courses
FROM   student s
JOIN   enrollment e ON s.student_id = e.student_id
JOIN   course c     ON e.course_id  = c.course_id
GROUP BY s.student_id
HAVING COUNT(*) >= 2
ORDER BY num_courses DESC;

-- D6: Average GPA per department — only depts above 3.0
SELECT '--- D6: High-GPA Departments (avg > 3.0) ---';
SELECT d.dept_name,
       ROUND(AVG(s.gpa), 2) AS avg_gpa
FROM   student s
JOIN   department d ON s.dept_id = d.dept_id
GROUP BY d.dept_id
HAVING AVG(s.gpa) > 3.0
ORDER BY avg_gpa DESC;

-- D7: Total credits per student
SELECT '--- D7: Total Credits per Student ---';
SELECT s.first_name || ' ' || s.last_name AS student,
       SUM(c.credits) AS total_credits,
       GROUP_CONCAT(c.course_name, ', ') AS courses
FROM   student s
JOIN   enrollment e ON s.student_id = e.student_id
JOIN   course c     ON e.course_id  = c.course_id
GROUP BY s.student_id
ORDER BY total_credits DESC;

-- ============================================================
-- PART E: UNION & SET OPERATIONS
-- ============================================================

SELECT '';
SELECT '============================';
SELECT 'PART E: UNION & SET OPERATIONS';
SELECT '============================';

-- E1: All people in the university
SELECT '--- E1: All People (UNION) ---';
SELECT first_name, last_name, 'Student' AS role
FROM   student
UNION
SELECT first_name, last_name, 'Instructor'
FROM   instructor
ORDER BY role, last_name;

-- E2: INTERSECT — departments with both students and courses
SELECT '--- E2: Depts with Students AND Courses (INTERSECT) ---';
SELECT d.dept_name
FROM department d
WHERE d.dept_id IN (
    SELECT dept_id FROM student WHERE dept_id IS NOT NULL
    INTERSECT
    SELECT dept_id FROM course WHERE dept_id IS NOT NULL
);

-- E3: EXCEPT — departments with courses but no students
SELECT '--- E3: Depts with Courses but No Students (EXCEPT) ---';
SELECT d.dept_name
FROM department d
WHERE d.dept_id IN (
    SELECT dept_id FROM course WHERE dept_id IS NOT NULL
    EXCEPT
    SELECT dept_id FROM student WHERE dept_id IS NOT NULL
);

-- ============================================================
-- PART F: SUBQUERIES
-- ============================================================

SELECT '';
SELECT '============================';
SELECT 'PART F: SUBQUERIES';
SELECT '============================';

-- F1: Students above average GPA (scalar subquery)
SELECT '--- F1: Students Above Average GPA ---';
SELECT first_name, last_name, gpa,
       (SELECT ROUND(AVG(gpa), 2) FROM student) AS avg_gpa
FROM   student
WHERE  gpa > (SELECT AVG(gpa) FROM student)
ORDER BY gpa DESC;

-- F2: Students in the highest-budget department
SELECT '--- F2: Students in Richest Department ---';
SELECT first_name, last_name
FROM   student
WHERE  dept_id = (
    SELECT dept_id FROM department ORDER BY budget DESC LIMIT 1
);

-- F3: Courses taken by the best student
SELECT '--- F3: Courses of Top Student ---';
SELECT c.course_name
FROM   course c
WHERE  c.course_id IN (
    SELECT e.course_id FROM enrollment e
    WHERE e.student_id = (
        SELECT student_id FROM student ORDER BY gpa DESC LIMIT 1
    )
);

-- F4: Correlated subquery — students above their dept average
SELECT '--- F4: Students Above Their Department Average ---';
SELECT s.first_name, s.last_name, s.gpa, s.dept_id,
       (SELECT ROUND(AVG(s2.gpa), 2) FROM student s2
        WHERE s2.dept_id = s.dept_id) AS dept_avg
FROM   student s
WHERE  s.gpa > (
    SELECT AVG(s2.gpa) FROM student s2
    WHERE s2.dept_id = s.dept_id
)
ORDER BY s.dept_id;

-- F5: EXISTS — students who have at least one 'A' grade
SELECT '--- F5: Students with at Least One A ---';
SELECT s.first_name, s.last_name
FROM   student s
WHERE  EXISTS (
    SELECT 1 FROM enrollment e
    WHERE e.student_id = s.student_id AND e.grade = 'A'
);

-- F6: NOT EXISTS — students NOT enrolled in any course
SELECT '--- F6: Students with No Enrollments ---';
SELECT s.first_name, s.last_name
FROM   student s
WHERE  NOT EXISTS (
    SELECT 1 FROM enrollment e
    WHERE e.student_id = s.student_id
);

-- F7: Derived table — department ranking
SELECT '--- F7: Department Ranking by Avg GPA ---';
SELECT dept_name, avg_gpa, student_count,
       (SELECT COUNT(*) FROM (
           SELECT d2.dept_id, AVG(s2.gpa) AS ag
           FROM department d2
           JOIN student s2 ON d2.dept_id = s2.dept_id
           GROUP BY d2.dept_id
       ) AS t WHERE t.ag > ds.avg_gpa) + 1 AS rank
FROM (
    SELECT d.dept_id, d.dept_name,
           ROUND(AVG(s.gpa), 2) AS avg_gpa,
           COUNT(*) AS student_count
    FROM department d
    JOIN student s ON d.dept_id = s.dept_id
    GROUP BY d.dept_id, d.dept_name
) AS ds
ORDER BY rank;

-- F8: Students who got 'A' in ALL their courses
SELECT '--- F8: Straight-A Students ---';
SELECT s.first_name, s.last_name, s.gpa
FROM   student s
WHERE  NOT EXISTS (
    SELECT 1 FROM enrollment e
    WHERE e.student_id = s.student_id AND e.grade != 'A'
)
AND EXISTS (
    SELECT 1 FROM enrollment e
    WHERE e.student_id = s.student_id
);

-- ============================================================
-- PART G: COMPLEX QUERIES & REPORTS
-- ============================================================

SELECT '';
SELECT '============================';
SELECT 'PART G: COMPLEX QUERIES';
SELECT '============================';

-- G1: Student Report Card
SELECT '--- G1: Student Report Cards ---';
SELECT s.first_name || ' ' || s.last_name AS student,
       s.gpa AS overall_gpa,
       c.course_name,
       c.credits,
       e.grade,
       e.semester
FROM   student s
JOIN   enrollment e ON s.student_id = e.student_id
JOIN   course c     ON e.course_id  = c.course_id
ORDER BY s.last_name, c.course_name;

-- G2: Course popularity with department info
SELECT '--- G2: Course Popularity Report ---';
SELECT c.course_name,
       d.dept_name AS offered_by,
       c.credits,
       COUNT(e.enrollment_id) AS enrolled,
       GROUP_CONCAT(e.grade, '') AS grade_list
FROM   course c
LEFT JOIN enrollment e ON c.course_id = e.course_id
LEFT JOIN department d ON c.dept_id   = d.dept_id
GROUP BY c.course_id
ORDER BY enrolled DESC;

-- G3: Department comprehensive report
SELECT '--- G3: Department Report ---';
SELECT d.dept_name,
       d.budget,
       COUNT(DISTINCT s.student_id) AS students,
       COUNT(DISTINCT c.course_id) AS courses,
       COUNT(DISTINCT i.instructor_id) AS instructors,
       ROUND(AVG(s.gpa), 2) AS avg_student_gpa
FROM   department d
LEFT JOIN student s    ON d.dept_id = s.dept_id
LEFT JOIN course c     ON d.dept_id = c.dept_id
LEFT JOIN instructor i ON d.dept_id = i.dept_id
GROUP BY d.dept_id
ORDER BY d.dept_name;

-- G4: Who has the highest GPA in each department?
SELECT '--- G4: Top Student per Department ---';
SELECT d.dept_name,
       s.first_name || ' ' || s.last_name AS top_student,
       s.gpa
FROM   student s
JOIN   department d ON s.dept_id = d.dept_id
WHERE  s.gpa = (
    SELECT MAX(s2.gpa)
    FROM student s2
    WHERE s2.dept_id = s.dept_id
)
ORDER BY s.gpa DESC;

-- ============================================================
-- SUMMARY: Row Counts
-- ============================================================

SELECT '';
SELECT '=== Database Summary ===';
SELECT 'department'  AS tbl, COUNT(*) AS rows FROM department
UNION ALL SELECT 'student',     COUNT(*) FROM student
UNION ALL SELECT 'course',      COUNT(*) FROM course
UNION ALL SELECT 'instructor',  COUNT(*) FROM instructor
UNION ALL SELECT 'enrollment',  COUNT(*) FROM enrollment
UNION ALL SELECT 'employee',    COUNT(*) FROM employee;

-- ============================================================
-- END OF WEEK 3 PRACTICE
-- ============================================================
SELECT '';
SELECT '✅ Week 3 practice complete!';
