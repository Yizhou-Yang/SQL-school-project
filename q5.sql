-- Lure Them Back

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q5 cascade;

CREATE TABLE q5 (
    patronID CHAR(20),
    email TEXT NOT NULL,
    usage INT,
    decline INT,
    missed INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.

-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS patrons CASCADE;
CREATE VIEW patrons AS
SELECT card_number
FROM Patron;

DROP VIEW IF EXISTS patron_active2018 CASCADE;
CREATE VIEW patron_active2018 AS
SELECT distinct patron, count(id) as checktimes
FROM Checkout
WHERE extract(year from checkout_time)=2018
GROUP BY patron
HAVING count(distinct extract(month from checkout_time)) = 12;

DROP VIEW IF EXISTS patron_active2019 CASCADE;
CREATE VIEW patron_active2019 AS
SELECT distinct patron, 12-count(distinct extract(month from checkout_time)) as missed, count(id) as checktimes
FROM patron_active2018 natural join Checkout
WHERE extract(year from checkout_time)=2019
GROUP BY patron
HAVING count(distinct extract(month from checkout_time)) >= 5 and count(distinct extract(month from checkout_time)) <= 11;

DROP VIEW IF EXISTS decline CASCADE;
CREATE VIEW decline AS
SELECT distinct patron_active2018.patron, (patron_active2018.checktimes-patron_active2019.checktimes) as decline
FROM patron_active2018,patron_active2019
WHERE patron_active2018.patron = patron_active2019.patron;

DROP VIEW IF EXISTS something2020 CASCADE;
CREATE VIEW something2020 AS
SELECT distinct patron
FROM Checkout
WHERE extract(year from checkout_time) = 2020;

DROP VIEW IF EXISTS nothing2020 CASCADE;
CREATE VIEW nothing2020 AS
SELECT distinct patron
FROM patron_active2019
WHERE patron not in (SELECT * FROM something2020);

DROP VIEW IF EXISTS usage CASCADE;
CREATE VIEW usage AS
SELECT distinct patron,count(distinct holding)as usage
FROM nothing2020 natural join Checkout
GROUP BY patron;

-- Your query that answers the question goes below the "insert into" line:
insert into q5
SELECT distinct card_number as patronID,email,usage,decline,missed
FROM usage,nothing2020,patron_active2019,decline,Patron
WHERE Patron.card_number = usage.patron and usage.patron = nothing2020.patron and nothing2020.patron = patron_active2019.patron and usage.patron = decline.patron;

