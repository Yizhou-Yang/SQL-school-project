-- Overdue Items

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q2 cascade;

create table q2 (
    branch CHAR(5),
    email TEXT,
    title TEXT,
    overdue INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS ParkdaleHPBranches CASCADE;
CREATE VIEW ParkdaleHPBranches AS
SELECT *
FROM LibraryBranch
WHERE (LibraryBranch.ward = ANY(
SELECT id from Ward
WHERE Ward.name = 'Parkdale-High Park'));

DROP VIEW IF EXISTS CheckedOut CASCADE;
CREATE VIEW CheckedOut AS SELECT *
FROM Checkout
WHERE Checkout.library = ANY(
SELECT code
FROM ParkdaleHPBranches);

DROP VIEW IF EXISTS ItemsOfInterest CASCADE;
CREATE VIEW ItemsOfInterest AS
SELECT patron, holding, library, htype, checkout_time, return_time
FROM (CheckedOut LEFT JOIN Return
 ON checkedout.id = return.checkout) as CheckReturn
 JOIN (SELECT id, htype FROM Holding) as htypes
 ON (checkreturn.holding = htypes.id);

DROP VIEW IF EXISTS Overdue CASCADE;
CREATE VIEW Overdue AS
SELECT patron, holding, library, htype, checkout_time,   
	CASE
		WHEN htype IN ('books','audiobooks') 
			THEN date_trunc('day', current_timestamp - checkout_time - interval '21 days')
		ELSE date_trunc('day', current_timestamp - checkout_time - interval '7 days')
	END 
 	AS overdue
FROM itemsofinterest
WHERE ( (checkout_time < (date_trunc('day', current_timestamp) - interval '21 days')
	AND return_time is null
	AND htype IN ('books','audiobooks')) 
	OR (checkout_time < (date_trunc('day', current_timestamp) - interval '7 days')
	AND return_time is null
	AND htype IN ('magazines and newspapers','movies','music'))
);


DROP VIEW IF EXISTS Output CASCADE;
CREATE VIEW Output AS
SELECT library as branch, email, title, EXTRACT(day from overdue) as overdue
FROM (overdue JOIN patron on (overdue.patron = patron.card_number)) as overduepatron
	JOIN holding ON (overduepatron.holding = holding.id);

-- Your query that answers the question goes below the "insert into" line:
insert into q2
SELECT * FROM Output;
