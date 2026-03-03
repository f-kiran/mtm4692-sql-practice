-- ============================================================
-- MTM4692 Applied SQL — Week 1: Introduction
-- Practice Code File (using longlist.db)
-- ============================================================
-- Download: github.com/f-kiran/mtm4692-sql-practice
-- Run with: sqlite3 longlist.db
-- Then:     .read week01_practice.sql
-- ============================================================

-- ============================================================
-- SETUP: Output formatting
-- ============================================================
.headers on
.mode box

-- ============================================================
-- SECTION 1: Exploring the Database
-- ============================================================

-- List all tables
.tables

-- View the schema (structure) of the table
.schema longlist

-- ============================================================
-- SECTION 2: SELECT — The Foundation
-- ============================================================

-- 2.1: Select specific columns
SELECT title, author FROM longlist;

-- 2.2: Select ALL columns (use sparingly!)
-- Warning: Avoid SELECT * in production — wastes bandwidth and memory
SELECT * FROM longlist;

-- 2.3: LIMIT the output — never SELECT * without LIMIT during exploration
SELECT title FROM longlist LIMIT 5;

-- 2.4: Select multiple columns with LIMIT
SELECT title, author, year, rating
FROM longlist
LIMIT 10;

-- ============================================================
-- SECTION 3: WHERE — Filtering Data
-- ============================================================

-- 3.1: Filter by a specific year
SELECT title FROM longlist WHERE year = 2023;

-- 3.2: Filter by a string value (use single quotes!)
SELECT * FROM longlist WHERE author = 'Andrey Kurkov';

-- 3.3: Comparison operators ( = != < > <= >= )
SELECT title, year, rating
FROM longlist
WHERE rating > 4.0;

-- 3.4: AND — multiple conditions
SELECT title, year, rating
FROM longlist
WHERE year = 2022 AND rating > 4.5;

-- 3.5: OR — at least one condition
SELECT title, author
FROM longlist
WHERE author = 'Fernanda Melchor' OR year = 2018;

-- ============================================================
-- SECTION 4: LIKE — Pattern Matching
-- ============================================================

-- % = any number of characters
-- _ = exactly one character

-- 4.1: Starts with 'The'
SELECT title FROM longlist WHERE title LIKE 'The%';

-- 4.2: Ends with 'ed'
SELECT title FROM longlist WHERE title LIKE '%ed';

-- 4.3: Contains 'night'
SELECT title FROM longlist WHERE title LIKE '%night%';

-- Note: SQLite LIKE is case-insensitive for ASCII characters
-- PostgreSQL LIKE is case-sensitive (use ILIKE for insensitive)

-- ============================================================
-- SECTION 5: NULL — Dealing with Missing Data
-- ============================================================

-- NULL is NOT 0 or "" — it means Unknown/Missing
-- You CANNOT use = NULL — you MUST use IS NULL

-- 5.1: Books with no translator
SELECT title FROM longlist WHERE translator IS NULL;

-- 5.2: Only translated works
SELECT title, translator
FROM longlist
WHERE translator IS NOT NULL;

-- ============================================================
-- SECTION 6: BETWEEN and IN — Range & Set Filtering
-- ============================================================

-- 6.1: BETWEEN — inclusive range
SELECT title, year
FROM longlist
WHERE year BETWEEN 2019 AND 2021;

-- 6.2: IN — filtering against a set of values
SELECT title, year
FROM longlist
WHERE year IN (2019, 2021, 2023);

-- ============================================================
-- SECTION 7: ORDER BY — Sorting Results
-- ============================================================

-- By default, no guaranteed order!

-- 7.1: Sort by year (ascending — default)
SELECT title, year FROM longlist ORDER BY year;

-- 7.2: Sort by title alphabetically
SELECT title, year FROM longlist ORDER BY title;

-- 7.3: ASC (default) vs DESC
-- ASC  = smallest to largest
-- DESC = largest to smallest
SELECT title, rating
FROM longlist
ORDER BY rating DESC;

-- 7.4: Multi-level sorting
-- Year newest first, then title alphabetically
SELECT year, title
FROM longlist
ORDER BY year DESC, title ASC;

-- ============================================================
-- SECTION 8: Arithmetic & Aliases
-- ============================================================

-- 8.1: Arithmetic in SELECT
SELECT title, (votes / 100) AS popularity_index
FROM longlist;

-- 8.2: Aliasing with AS — rename columns for clarity
SELECT COUNT(*) AS total_books FROM longlist;

-- ============================================================
-- SECTION 9: Aggregate Functions
-- ============================================================

-- Functions that take many values and return a single result

-- 9.1: COUNT
-- Total rows
SELECT COUNT(*) FROM longlist;

-- Total non-null translators
SELECT COUNT(translator) FROM longlist;

-- 9.2: AVG
SELECT AVG(rating) FROM longlist;

-- 9.3: SUM
SELECT SUM(votes) FROM longlist WHERE year = 2021;

-- 9.4: MIN and MAX
SELECT MIN(rating), MAX(rating) FROM longlist;

-- 9.5: ROUND — keep output clean
SELECT ROUND(AVG(rating), 2) AS 'Clean Average'
FROM longlist;

-- ============================================================
-- SECTION 10: DISTINCT — Removing Duplicates
-- ============================================================

-- 10.1: List unique years in the database
SELECT DISTINCT year FROM longlist ORDER BY year;

-- 10.2: Count distinct authors
SELECT COUNT(DISTINCT author) AS unique_authors FROM longlist;

-- ============================================================
-- SECTION 11: Combining Functions
-- ============================================================

-- 11.1: Rating spread
SELECT MAX(rating) - MIN(rating) AS rating_spread
FROM longlist;

-- 11.2: Average pages per book, rounded
SELECT ROUND(AVG(pages), 0) AS avg_pages FROM longlist;

-- 11.3: Books per year
SELECT year, COUNT(*) AS books_count
FROM longlist
GROUP BY year
ORDER BY year;

-- 11.4: Average rating per year
SELECT year,
       COUNT(*) AS books,
       ROUND(AVG(rating), 2) AS avg_rating,
       ROUND(AVG(pages), 0) AS avg_pages
FROM longlist
GROUP BY year
ORDER BY year;

-- ============================================================
-- SECTION 12: SQL Comments
-- ============================================================

-- Single line comment (using --)
/* Multi-line
   comment
   using slash-star */

-- ============================================================
-- MINI-CHALLENGES
-- ============================================================

-- Challenge 1: Find the top 3 books from 2022 with the most votes
-- Hint: WHERE, ORDER BY DESC, LIMIT
SELECT title, author, votes
FROM longlist
WHERE year = 2022
ORDER BY votes DESC
LIMIT 3;

-- Challenge 2: Find the average rating for books containing "Chronicle"
-- Hint: LIKE, AVG()
SELECT ROUND(AVG(rating), 2) AS avg_chronicle_rating
FROM longlist
WHERE title LIKE '%Chronicle%';

-- Challenge 3: Find all paperback books with rating above 4.0
SELECT title, author, format, rating
FROM longlist
WHERE format = 'paperback' AND rating > 4.0
ORDER BY rating DESC;

-- Challenge 4: Which publisher has the most books on the longlist?
SELECT publisher, COUNT(*) AS book_count
FROM longlist
GROUP BY publisher
ORDER BY book_count DESC
LIMIT 5;

-- Challenge 5: Find books with more than 400 pages, sorted by pages
SELECT title, author, pages
FROM longlist
WHERE pages > 400
ORDER BY pages DESC;

-- ============================================================
-- SQL EXECUTION ORDER (Remember!)
-- ============================================================
-- Even though you WRITE: SELECT ... FROM ... WHERE ... ORDER BY ... LIMIT
-- The database EXECUTES:
--   1. FROM    (get the data)
--   2. WHERE   (filter rows)
--   3. SELECT  (choose columns)
--   4. ORDER BY (sort results)
--   5. LIMIT   (trim output)

-- ============================================================
-- SUMMARY: Today's Toolkit
-- ============================================================
-- Environment : SQLite + VS Code
-- Retrieval   : SELECT, DISTINCT
-- Refinement  : WHERE, LIKE, BETWEEN, IN, IS NULL
-- Organization: ORDER BY, LIMIT
-- Math        : COUNT, SUM, AVG, MIN, MAX, ROUND
-- ============================================================
