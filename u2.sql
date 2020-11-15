-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.


-- Define views for your intermediate steps here, and end with a
-- INSERT, DELETE, or UPDATE statement.

-- get downsview branch(es)
DROP VIEW IF EXISTS CheckedOut CASCADE;
CREATE VIEW CheckedOut AS SELECT *
FROM Checkout
WHERE Checkout.library = ANY(
	SELECT code FROM LibraryBranch
	WHERE LibraryBranch.name = 'Downsview');

-- retrieve books checked out but unreturned from downsview
DROP VIEW IF EXISTS BooksOut CASCADE;
CREATE VIEW BooksOut AS
SELECT patron, holding, checkout_time, current_timestamp - checkout_time as time_out
FROM (CheckedOut LEFT JOIN Return
 ON checkedout.id = return.checkout) as CheckReturn
 JOIN (SELECT id, htype FROM Holding) as htypes
 ON (checkreturn.holding = htypes.id)
WHERE htype = 'books' AND return_time is NULL;

-- get list of patrons with overdue books from downsview
-- who are eligible for extension
DROP VIEW IF EXISTS EligiblePatrons CASCADE;
CREATE VIEW EligiblePatrons AS
SELECT patron
FROM BooksOut
GROUP BY patron
HAVING COUNT(holding) <= 5 AND EXTRACT(day from MAX(time_out)) < 28;

-- find checkouts that can be extended
DROP VIEW IF EXISTS Extensions CASCADE;
CREATE VIEW Extensions AS
SELECT patron, holding, checkout_time
FROM BooksOut
WHERE patron = ANY(SELECT * FROM EligiblePatrons)
	AND EXTRACT(day from (current_timestamp - checkout_time)) > 21;

-- update checkout data to 'extend' checkout time
UPDATE checkout SET checkout_time = checkout_time + interval '14 days'
WHERE (checkout.patron, checkout.holding, checkout.checkout_time) = ANY(
	SELECT patron, holding, checkout_time FROM Extensions)
AND checkout.library = ANY(
	SELECT code FROM LibraryBranch
	WHERE LibraryBranch.name = 'Downsview');
