\set MYSQL_HOST			'\'localhost\''
\set MYSQL_PORT			'\'3306\''
\set MYSQL_USER_NAME	'\'edb\''
\set MYSQL_PASS			'\'edb\''

-- Before running this file User must create database mysql_fdw_regress on
-- MySQL with all permission for 'edb' user with 'edb' password and ran
-- mysql_init.sh file to create tables.

\c contrib_regression
CREATE EXTENSION IF NOT EXISTS mysql_fdw;
CREATE SERVER mysql_svr FOREIGN DATA WRAPPER mysql_fdw
  OPTIONS (host :MYSQL_HOST, port :MYSQL_PORT);
CREATE USER MAPPING FOR PUBLIC SERVER mysql_svr
  OPTIONS (username :MYSQL_USER_NAME, password :MYSQL_PASS);

-- Check version
SELECT mysql_fdw_version();

-- Create foreign tables
CREATE FOREIGN TABLE f_mysql_test(a int, b int)
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'mysql_test');
CREATE FOREIGN TABLE f_numbers(a int, b varchar(255))
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'numbers');
CREATE FOREIGN TABLE f_test_tbl1 (c1 INTEGER, c2 VARCHAR(10), c3 CHAR(9),c4 BIGINT, c5 pg_catalog.Date, c6 DECIMAL, c7 INTEGER, c8 SMALLINT)
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'test_tbl1');
CREATE FOREIGN TABLE f_test_tbl2 (c1 INTEGER, c2 VARCHAR(14), c3 VARCHAR(13))
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'test_tbl2');
CREATE TYPE size_t AS enum('small','medium','large');
CREATE FOREIGN TABLE f_enum_t1(id int, size size_t)
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'enum_t1');

-- Insert data in MySQL db using foreign tables
INSERT INTO f_test_tbl1 VALUES (100, 'EMP1', 'ADMIN', 1300, '1980-12-17', 800.23, NULL, 20);
INSERT INTO f_test_tbl1 VALUES (200, 'EMP2', 'SALESMAN', 600, '1981-02-20', 1600.00, 300, 30);
INSERT INTO f_test_tbl1 VALUES (300, 'EMP3', 'SALESMAN', 600, '1981-02-22', 1250, 500, 30);
INSERT INTO f_test_tbl1 VALUES (400, 'EMP4', 'MANAGER', 900, '1981-04-02', 2975.12, NULL, 20);
INSERT INTO f_test_tbl1 VALUES (500, 'EMP5', 'SALESMAN', 600, '1981-09-28', 1250, 1400, 30);
INSERT INTO f_test_tbl1 VALUES (600, 'EMP6', 'MANAGER', 900, '1981-05-01', 2850, NULL, 30);
INSERT INTO f_test_tbl1 VALUES (700, 'EMP7', 'MANAGER', 900, '1981-06-09', 2450.45, NULL, 10);
INSERT INTO f_test_tbl1 VALUES (800, 'EMP8', 'FINANCE', 400, '1987-04-19', 3000, NULL, 20);
INSERT INTO f_test_tbl1 VALUES (900, 'EMP9', 'HEAD', NULL, '1981-11-17', 5000, NULL, 10);
INSERT INTO f_test_tbl1 VALUES (1000, 'EMP10', 'SALESMAN', 600, '1980-09-08', 1500, 0, 30);
INSERT INTO f_test_tbl1 VALUES (1100, 'EMP11', 'ADMIN', 800, '1987-05-23', 1100, NULL, 20);
INSERT INTO f_test_tbl1 VALUES (1200, 'EMP12', 'ADMIN', 600, '1981-12-03', 950, NULL, 30);
INSERT INTO f_test_tbl1 VALUES (1300, 'EMP13', 'FINANCE', 400, '1981-12-03', 3000, NULL, 20);
INSERT INTO f_test_tbl1 VALUES (1400, 'EMP14', 'ADMIN', 700, '1982-01-23', 1300, NULL, 10);
INSERT INTO f_test_tbl2 VALUES(10, 'DEVELOPMENT', 'PUNE');
INSERT INTO f_test_tbl2 VALUES(20, 'ADMINISTRATION', 'BANGLORE');
INSERT INTO f_test_tbl2 VALUES(30, 'SALES', 'MUMBAI');
INSERT INTO f_test_tbl2 VALUES(40, 'HR', 'NAGPUR');

SET datestyle TO ISO;

-- Retrieve Data from Foreign Table using SELECT Statement.
SELECT c1, c2, c3, c4, c5, c6, c7, c8 FROM f_test_tbl1
  ORDER BY c1 DESC, c8;
SELECT DISTINCT c8 FROM f_test_tbl1 ORDER BY 1;
SELECT c2 AS "Employee Name" FROM f_test_tbl1 ORDER BY 1;
SELECT c8, c6, c7 FROM f_test_tbl1 ORDER BY 1, 2, 3;
SELECT c1, c2, c3, c4, c5, c6, c7, c8 FROM f_test_tbl1
  WHERE c1 = 100 ORDER BY 1;
SELECT c1, c2, c3, c4, c5, c6, c7, c8 FROM f_test_tbl1
  WHERE c1 = 100 OR c1 = 700 ORDER BY 1;
SELECT * FROM f_test_tbl1 WHERE c3 like 'SALESMAN' ORDER BY 1;
SELECT * FROM f_test_tbl1 WHERE c1 IN (100, 700) ORDER BY 1;
SELECT * FROM f_test_tbl1 WHERE c1 NOT IN (100, 700) ORDER BY 1 LIMIT 5;
SELECT * FROM f_test_tbl1 WHERE c8 BETWEEN 10 AND 20 ORDER BY 1;
SELECT * FROM f_test_tbl1 ORDER BY 1 OFFSET 5;

-- Retrieve Data from Foreign Table using Group By Clause.
SELECT c8 "Department", COUNT(c1) "Total Employees" FROM f_test_tbl1
  GROUP BY c8 ORDER BY c8;
SELECT c8, SUM(c6) FROM f_test_tbl1
  GROUP BY c8 HAVING c8 IN (10, 30) ORDER BY c8;
SELECT c8, SUM(c6) FROM f_test_tbl1
  GROUP BY c8 HAVING SUM(c6) > 9400 ORDER BY c8;

-- Row Level Functions
SELECT UPPER(c2), LOWER(c2) FROM f_test_tbl2 ORDER BY 1, 2;

-- Retrieve Data from Foreign Table using Sub Queries.
SELECT * FROM f_test_tbl1
  WHERE c8 <> ALL (SELECT c1 FROM f_test_tbl2 WHERE c1 IN (10, 30, 40))
  ORDER BY c1;
SELECT c1, c2, c3 FROM f_test_tbl2
  WHERE EXISTS (SELECT 1 FROM f_test_tbl1 WHERE f_test_tbl2.c1 = f_test_tbl1.c8)
  ORDER BY 1, 2;
SELECT c1, c2, c3, c4, c5, c6, c7, c8 FROM f_test_tbl1
  WHERE c8 NOT IN (SELECT c1 FROM f_test_tbl2) ORDER BY c1;

-- Retrieve Data from Foreign Table using UNION Operator.
SELECT c1, c2 FROM f_test_tbl2 UNION
SELECT c1, c2 FROM f_test_tbl1 ORDER BY c1;

SELECT c2 FROM f_test_tbl2  UNION ALL
SELECT c2 FROM f_test_tbl1 ORDER BY c2;

-- Retrieve Data from Foreign Table using INTERSECT Operator.
SELECT c2 FROM f_test_tbl1 WHERE c1 >= 800 INTERSECT
SELECT c2 FROM f_test_tbl1 WHERE c1 >= 400 ORDER BY c2;

SELECT c2 FROM f_test_tbl1 WHERE c1 >= 800 INTERSECT ALL
SELECT c2 FROM f_test_tbl1 WHERE c1 >= 400 ORDER BY c2;

-- Retrieve Data from Foreign Table using EXCEPT.
SELECT c2 FROM f_test_tbl1 EXCEPT
SELECT c2 FROM f_test_tbl1 WHERE c1 > 900 ORDER BY c2;

SELECT c2 FROM f_test_tbl1 EXCEPT ALL
SELECT c2 FROM f_test_tbl1 WHERE c1 > 900 ORDER BY c2;

-- Retrieve Data from Foreign Table using CTE (With Clause).
WITH
  with_qry AS (SELECT c1, c2, c3 FROM f_test_tbl2)
SELECT e.c2, e.c6, w.c1, w.c2 FROM f_test_tbl1 e, with_qry w
  WHERE e.c8 = w.c1 ORDER BY e.c8, e.c2;

WITH
  test_tbl2_costs AS (SELECT d.c2, SUM(c6) test_tbl2_total FROM f_test_tbl1 e, f_test_tbl2 d
    WHERE e.c8 = d.c1 GROUP BY 1),
  avg_cost AS (SELECT SUM(test_tbl2_total)/COUNT(*) avg FROM test_tbl2_costs)
SELECT * FROM test_tbl2_costs
  WHERE test_tbl2_total > (SELECT avg FROM avg_cost) ORDER BY c2;

-- Retrieve Data from Foreign Table using Window Clause.
SELECT c8, c1, c6, AVG(c6) OVER (PARTITION BY c8) FROM f_test_tbl1
  ORDER BY c8, c1;
SELECT c8, c1, c6, COUNT(c6) OVER (PARTITION BY c8) FROM f_test_tbl1
  WHERE c8 IN (10, 30, 40, 50, 60, 70) ORDER BY c8, c1;
SELECT c8, c1, c6, SUM(c6) OVER (PARTITION BY c8) FROM f_test_tbl1
  ORDER BY c8, c1;

-- Views
CREATE VIEW smpl_vw AS
  SELECT c1, c2, c3, c4, c5, c6, c7, c8 FROM f_test_tbl1
    ORDER BY c1;
SELECT * FROM smpl_vw ORDER BY 1;

CREATE VIEW comp_vw (s1, s2, s3, s6, s7, s8, d2) AS
  SELECT s.c1, s.c2, s.c3, s.c6, s.c7, s.c8, d.c2
    FROM f_test_tbl2 d, f_test_tbl1 s WHERE d.c1 = s.c8 AND d.c1 = 10
    ORDER BY s.c1;
SELECT * FROM comp_vw ORDER BY 1;

CREATE TEMPORARY VIEW ttest_tbl1_vw AS
  SELECT c1, c2, c3 FROM f_test_tbl2;
SELECT * FROM ttest_tbl1_vw ORDER BY 1, 2;

CREATE VIEW mul_tbl_view AS
  SELECT d.c1 dc1, d.c2 dc2, e.c1 ec1, e.c2 ec2, e.c6 ec6
    FROM f_test_tbl2 d INNER JOIN f_test_tbl1 e ON d.c1 = e.c8 ORDER BY d.c1;
SELECT * FROM mul_tbl_view ORDER BY 1, 2,3;

-- Insert Some records in numbers table.
INSERT INTO f_numbers VALUES (1, 'One');
INSERT INTO f_numbers VALUES (2, 'Two');
INSERT INTO f_numbers VALUES (3, 'Three');
INSERT INTO f_numbers VALUES (4, 'Four');
INSERT INTO f_numbers VALUES (5, 'Five');
INSERT INTO f_numbers VALUES (6, 'Six');
INSERT INTO f_numbers VALUES (7, 'Seven');
INSERT INTO f_numbers VALUES (8, 'Eight');
INSERT INTO f_numbers VALUES (9, 'Nine');

-- Retrieve Data From foreign tables in functions.
CREATE OR REPLACE FUNCTION test_param_where() RETURNS void AS $$
DECLARE
  n varchar;
BEGIN
  FOR x IN 1..9 LOOP
    SELECT b INTO n FROM f_numbers WHERE a = x;
    RAISE NOTICE 'Found number %', n;
  END LOOP;
  return;
END
$$ LANGUAGE plpgsql;

SELECT test_param_where();

CREATE OR REPLACE FUNCTION test_param_where2(int, text) RETURNS integer AS '
  SELECT a FROM f_numbers WHERE a = $1 AND b = $2;
' LANGUAGE sql;

SELECT test_param_where2(1, 'One');

-- Foreign-Foreign table joins

-- CROSS JOIN.
SELECT f_test_tbl2.c2, f_test_tbl1.c2 FROM f_test_tbl2 CROSS JOIN f_test_tbl1 ORDER BY 1, 2;
-- INNER JOIN.
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d, f_test_tbl1 e WHERE d.c1 = e.c8 ORDER BY 1, 3;
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d INNER JOIN f_test_tbl1 e ON d.c1 = e.c8 ORDER BY 1, 3;
-- OUTER JOINS.
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d LEFT OUTER JOIN f_test_tbl1 e ON d.c1 = e.c8 ORDER BY 1, 3;
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d RIGHT OUTER JOIN f_test_tbl1 e ON d.c1 = e.c8 ORDER BY 1, 3;
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d FULL OUTER JOIN f_test_tbl1 e ON d.c1 = e.c8 ORDER BY 1, 3;

-- Local-Foreign table joins.
CREATE TABLE l_test_tbl1 AS
  SELECT c1, c2, c3, c4, c5, c6, c7, c8 FROM f_test_tbl1;
CREATE TABLE l_test_tbl2 AS
  SELECT c1, c2, c3 FROM f_test_tbl2;

-- CROSS JOIN.
SELECT f_test_tbl2.c2, l_test_tbl1.c2 FROM f_test_tbl2 CROSS JOIN l_test_tbl1 ORDER BY 1, 2;
-- INNER JOIN.
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM l_test_tbl2 d, f_test_tbl1 e WHERE d.c1 = e.c8 ORDER BY 1, 3;
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d INNER JOIN l_test_tbl1 e ON d.c1 = e.c8 ORDER BY 1, 3;
-- OUTER JOINS.
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d LEFT OUTER JOIN l_test_tbl1 e ON d.c1 = e.c8 ORDER BY 1, 3;
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d RIGHT OUTER JOIN l_test_tbl1 e ON d.c1 = e.c8 ORDER BY 1, 3;
SELECT d.c1, d.c2, e.c1, e.c2, e.c6, e.c8
  FROM f_test_tbl2 d FULL OUTER JOIN l_test_tbl1 e ON d.c1 = e.c8 ORDER BY 1, 3;

-- FDW-206: LEFT JOIN LATERAL case should not crash
EXPLAIN (VERBOSE, COSTS OFF)
SELECT * FROM f_mysql_test t1 LEFT JOIN LATERAL (
  SELECT t2.a, t1.a AS t1_a FROM f_mysql_test t2) t3 ON t1.a = t3.a ORDER BY 1;
SELECT * FROM f_mysql_test t1 LEFT JOIN LATERAL (
  SELECT t2.a, t1.a AS t1_a FROM f_mysql_test t2) t3 ON t1.a = t3.a ORDER BY 1;
SELECT t1.c1, t3.c1, t3.t1_c8 FROM f_test_tbl1 t1 INNER JOIN LATERAL (
  SELECT t2.c1, t1.c8 AS t1_c8 FROM f_test_tbl2 t2) t3 ON t3.c1 = t3.t1_c8
  ORDER BY 1, 2, 3;
SELECT t1.c1, t3.c1, t3.t1_c8 FROM l_test_tbl1 t1 LEFT JOIN LATERAL (
  SELECT t2.c1, t1.c8 AS t1_c8 FROM f_test_tbl2 t2) t3 ON t3.c1 = t3.t1_c8
  ORDER BY 1, 2, 3;
SELECT *, (SELECT r FROM (SELECT c1 AS c1) x, LATERAL (SELECT c1 AS r) y)
  FROM f_test_tbl1 ORDER BY 1, 2, 3;
-- LATERAL JOIN with RIGHT should throw error
SELECT t1.c1, t3.c1, t3.t1_c8 FROM f_test_tbl1 t1 RIGHT JOIN LATERAL (
  SELECT t2.c1, t1.c8 AS t1_c8 FROM f_test_tbl2 t2) t3 ON t3.c1 = t3.t1_c8
  ORDER BY 1, 2, 3;

-- FDW-207: NATURAL JOIN should give correct output
SELECT t1.c1, t2.c1, t3.c1
  FROM f_test_tbl1 t1 NATURAL JOIN f_test_tbl1 t2 NATURAL JOIN f_test_tbl1 t3
  ORDER BY 1, 2, 3;

-- FDW-208: IS NULL and LIKE should give the correct output with
-- use_remote_estimate set to true.
INSERT INTO f_test_tbl2 VALUES (50, 'TEMP1', NULL);
INSERT INTO f_test_tbl2 VALUES (60, 'TEMP2', NULL);
ALTER SERVER mysql_svr OPTIONS (use_remote_estimate 'true');
SELECT t1.c1, t2.c1
  FROM f_test_tbl2 t1 INNER JOIN f_test_tbl2 t2 ON t1.c1 = t2.c1
  WHERE t1.c3 IS NULL ORDER BY 1, 2;
SELECT t1.c1, t2.c1
  FROM f_test_tbl2 t1 INNER JOIN f_test_tbl2 t2 ON t1.c1 = t2.c1 AND t1.c2 LIKE 'TEMP%'
  ORDER BY 1, 2;
DELETE FROM f_test_tbl2 WHERE c1 IN (50, 60);
ALTER SERVER mysql_svr OPTIONS (SET use_remote_estimate 'false');

-- FDW-169: Insert/Update/Delete on enum column.
INSERT INTO f_enum_t1
  VALUES (1, 'small'), (2, 'medium'), (3, 'medium'), (4, 'small');
SELECT * FROM f_enum_t1 WHERE id = 4;
UPDATE f_enum_t1 SET size = 'large' WHERE id = 4;
SELECT * FROM f_enum_t1 WHERE id = 4;
DELETE FROM f_enum_t1 WHERE size = 'large';
SELECT * FROM f_enum_t1 WHERE id = 4;

-- Negative scenarios for ENUM handling.
-- Test that if we insert the ENUM value which is not present on MySQL side,
-- but present on Postgres side.
DROP FOREIGN TABLE f_enum_t1;
DROP TYPE size_t;
-- Create the type with extra enum values.
CREATE TYPE size_t AS enum('small', 'medium', 'large', 'largest', '');
CREATE FOREIGN TABLE f_enum_t1(id int, size size_t)
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'enum_t1');

-- If we insert the enum value which is not present on MySQL side then it
-- inserts empty string in ANSI_QUOTES sql_mode, so verify that.
INSERT INTO f_enum_t1 VALUES (4, 'largest');
SELECT * from f_enum_t1;
DELETE FROM f_enum_t1 WHERE size = '';

-- Postgres should throw an error as the value which we are inserting for enum
-- column is not present in enum on Postgres side, no matter whether it is
-- present on MySQL side or not. PG's sanity check itself throws an error.
INSERT INTO f_enum_t1 VALUES (4, 'big');

-- FDW-155: Enum data type can be handled correctly in select statements on
-- foreign table.
SELECT * FROM f_enum_t1 WHERE size = 'medium' ORDER BY id;

-- Remote aggregate in combination with a local Param (for the output
-- of an initplan)
EXPLAIN (VERBOSE, COSTS OFF)
SELECT EXISTS(SELECT 1 FROM pg_enum), sum(id) from f_enum_t1;
SELECT EXISTS(SELECT 1 FROM pg_enum), sum(id) from f_enum_t1;

-- Check with the IMPORT FOREIGN SCHEMA command.  Also, check ENUM types with
-- the IMPORT FOREIGN SCHEMA command. If the enum name is the same for multiple
-- tables, then it should handle correctly by prefixing the table name.
CREATE TYPE enum_t1_size_t AS enum('small', 'medium', 'large');
CREATE TYPE enum_t2_size_t AS enum('S', 'M', 'L');
IMPORT FOREIGN SCHEMA mysql_fdw_regress LIMIT TO (enum_t1, enum_t2)
  FROM SERVER mysql_svr INTO public;
SELECT attrelid::regclass, atttypid::regtype FROM pg_attribute
  WHERE (attrelid = 'enum_t1'::regclass OR attrelid = 'enum_t2'::regclass) AND
    attnum > 1 ORDER BY 1;
SELECT * FROM enum_t1 ORDER BY id;
SELECT * FROM enum_t2 ORDER BY id;
DROP FOREIGN TABLE enum_t1;
DROP FOREIGN TABLE enum_t2;

-- Parameterized queries should work correctly.
EXPLAIN (VERBOSE, COSTS OFF)
SELECT c1, c2 FROM f_test_tbl1
  WHERE c8 = (SELECT c1 FROM f_test_tbl2 WHERE c1 = (SELECT 20))
  ORDER BY c1;
SELECT c1, c2 FROM f_test_tbl1
  WHERE c8 = (SELECT c1 FROM f_test_tbl2 WHERE c1 = (SELECT 20))
  ORDER BY c1;

SELECT * FROM f_test_tbl1
  WHERE c8 NOT IN (SELECT c1 FROM f_test_tbl2 WHERE c1 = (SELECT 20))
  ORDER BY c1;

-- Check parameterized queries with text/varchar column, should not crash.
CREATE FOREIGN TABLE f_test_tbl3 (c1 INTEGER, c2 text, c3 text)
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'test_tbl2');
CREATE TABLE local_t1 (c1 INTEGER, c2 text);
INSERT INTO local_t1 VALUES (1, 'SALES');

SELECT c1, c2 FROM f_test_tbl3 WHERE c3 = (SELECT 'PUNE'::text) ORDER BY c1;
SELECT c1, c2 FROM f_test_tbl2 WHERE c3 = (SELECT 'PUNE'::varchar) ORDER BY c1;

SELECT * FROM local_t1 lt1 WHERE lt1.c1 =
  (SELECT count(*) FROM f_test_tbl3 ft1 WHERE ft1.c2 = lt1.c2) ORDER BY lt1.c1;

EXPLAIN (VERBOSE, COSTS OFF)
SELECT c1, c2 FROM f_test_tbl1 WHERE c8 = (
  SELECT c1 FROM f_test_tbl2 WHERE c1 = (
    SELECT min(c1) + 1 FROM f_test_tbl2)) ORDER BY c1;
SELECT c1, c2 FROM f_test_tbl1 WHERE c8 = (
  SELECT c1 FROM f_test_tbl2 WHERE c1 = (
    SELECT min(c1) + 1 FROM f_test_tbl2)) ORDER BY c1;

SELECT * FROM f_test_tbl1 WHERE c1 = (SELECT 500) AND c2 = (
  SELECT max(c2) FROM f_test_tbl1 WHERE c4 = (SELECT 600))
  ORDER BY 1, 2;
SELECT t1.c1, (SELECT c2 FROM f_test_tbl1 WHERE c1 =(SELECT 500))
  FROM f_test_tbl2 t1, (
    SELECT c1, c2 FROM f_test_tbl2 WHERE c1 > ANY (SELECT 20)) t2
  ORDER BY 1, 2;

-- Issue #202 - correct handling of mixed-case table names.
IMPORT FOREIGN SCHEMA mysql_fdw_regress LIMIT TO ("mixedCaseTable") FROM SERVER mysql_svr INTO public;
SELECT * FROM "mixedCaseTable" ORDER BY id;
DROP FOREIGN TABLE "mixedCaseTable";

-- Cleanup
DROP TABLE l_test_tbl1;
DROP TABLE l_test_tbl2;
DROP TABLE local_t1;
DROP VIEW smpl_vw;
DROP VIEW comp_vw;
DROP VIEW ttest_tbl1_vw;
DROP VIEW mul_tbl_view;
DELETE FROM f_test_tbl1;
DELETE FROM f_test_tbl2;
DELETE FROM f_numbers;
DELETE FROM f_enum_t1;
DROP FOREIGN TABLE f_test_tbl1;
DROP FOREIGN TABLE f_test_tbl2;
DROP FOREIGN TABLE f_numbers;
DROP FOREIGN TABLE f_mysql_test;
DROP FOREIGN TABLE f_enum_t1;
DROP FOREIGN TABLE f_test_tbl3;
DROP TYPE size_t;
DROP TYPE enum_t1_size_t;
DROP TYPE enum_t2_size_t;
DROP FUNCTION test_param_where();
DROP FUNCTION test_param_where2(int, text);
DROP USER MAPPING FOR public SERVER mysql_svr;
DROP SERVER mysql_svr;
DROP EXTENSION mysql_fdw;
