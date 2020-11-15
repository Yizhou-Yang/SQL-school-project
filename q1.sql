-- Branch Activity

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q1 cascade;

CREATE TABLE q1 (
    branch CHAR(5),
    year INT,
    events INT NOT NULL,
    sessions FLOAT NOT NULL,
    registration INT NOT NULL,
    holdings INT NOT NULL,
    checkouts INT NOT NULL,
    duration FLOAT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.

-- Define views for your intermediate steps here:
--
--100 lines
DROP VIEW IF EXISTS allevents CASCADE;
CREATE VIEW allevents AS
SELECT LibraryBranch.code, LibraryEvent.id as event
FROM LibraryBranch,LibraryRoom,LibraryEvent
WHERE LibraryRoom.library = LibraryBranch.code and LibraryRoom.id = LibraryEvent.room;

--242 lines
DROP VIEW IF EXISTS eventsinrange CASCADE;
CREATE VIEW eventsinrange AS
SELECT code, event, extract(year from edate) as year
FROM EventSchedule NATURAL JOIN allevents
WHERE extract(year from edate)<=2019 and extract(year from edate)>=2015;

DROP VIEW IF EXISTS uniqueevent CASCADE;
CREATE VIEW uniqueevent AS
SELECT DISTINCT code, event, year
FROM eventsinrange;

--10 lines
DROP VIEW IF EXISTS sessions CASCADE;
CREATE VIEW sessions AS
SELECT code, year, count(distinct event) as events, CAST(count(event) AS float)/CAST(count(distinct event) AS float) as sessions
FROM eventsinrange
GROUP BY code,year;

--5 events, all happening in one place
DROP VIEW IF EXISTS registrations CASCADE;
CREATE VIEW registrations AS
SELECT code, year, count(*) as registration
FROM uniqueevent NATURAL JOIN EventSignUp
GROUP BY code,year;

DROP VIEW IF EXISTS eventinfo CASCADE;
CREATE VIEW eventinfo AS
SELECT code, events, sessions, registration
FROM sessions NATURAL JOIN registrations;


DROP TABLE IF EXISTS years CASCADE;
CREATE TABLE years(year INT);
INSERT INTO years VALUES
(2015),(2016),(2017),(2018),(2019);


DROP VIEW IF EXISTS branchyears CASCADE;
CREATE VIEW branchyears AS
SELECT code as branch,year
FROM LibraryBranch,years;

DROP VIEW IF EXISTS holdings CASCADE;
CREATE VIEW holdings AS
SELECT library as branch,sum(num_holdings) as holdings
FROM LibraryCatalogue 
GROUP BY library;

--years with sessions and null values
DROP VIEW IF EXISTS branchyearsfixed CASCADE;
CREATE VIEW branchyearsfixed AS
SELECT code as branch, year, events, sessions, registration
FROM sessions NATURAL FULL JOIN eventinfo;

--209 rows
DROP VIEW IF EXISTS checkoutinrange CASCADE;
CREATE VIEW checkoutinrange AS
SELECT library,count(id) as checkouts, extract(year from checkout_time) as year
FROM Checkout
where extract(year from checkout_time)<=2019 and extract(year from checkout_time)>=2015
GROUP BY library,year;

DROP VIEW IF EXISTS checkoutraw CASCADE;
CREATE VIEW checkoutraw AS
SELECT library,id, checkout_time,extract(year from checkout_time) as year
FROM Checkout
where extract(year from checkout_time) <=2019 and extract(year from checkout_time) >=2015;

DROP VIEW IF EXISTS duration CASCADE;
CREATE VIEW duration AS
SELECT library, avg(date_trunc('day',return_time)::date-date_trunc('day',checkout_time)::date) as duration, year
FROM Return, checkoutraw
WHERE checkoutraw.id = Return.checkout
GROUP BY library,year;

DROP VIEW IF EXISTS eventsresult CASCADE;
CREATE VIEW eventsresult AS
SELECT branch, year, events, sessions, registration,holdings
FROM branchyearsfixed NATURAL FULL JOIN branchyears NATURAL FULL JOIN holdings;

DROP VIEW IF EXISTS booksresult CASCADE;
CREATE VIEW booksresult AS
SELECT library as branch,year,checkouts,duration
FROM (duration NATURAL FULL JOIN checkoutinrange);

-- Your query that answers the question goes below the "insert into" line:
insert into q1
SELECT branch,year,COALESCE(events,0),COALESCE(sessions,0),COALESCE(registration,0),COALESCE(holdings,0),COALESCE(checkouts,0),COALESCE(duration,0)
FROM booksresult NATURAL FULL JOIN eventsresult;

