-- Promotion

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q3 cascade;

create domain patronCategory as varchar(10)
  check (value in ('inactive', 'reader', 'doer', 'keener'));

create table q3 (
    patronID Char(20),
    category patronCategory
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
-- Define views for your intermediate steps here:

DROP VIEW IF EXISTS mypatron CASCADE;
CREATE VIEW mypatron AS
SELECT card_number as patron
FROM Patron;

DROP VIEW IF EXISTS allevents CASCADE;
CREATE VIEW allevents AS
SELECT LibraryBranch.code, LibraryEvent.id as event
FROM LibraryBranch,LibraryRoom,LibraryEvent
WHERE LibraryRoom.library = LibraryBranch.code and LibraryRoom.id = LibraryEvent.room;

--200 rows
DROP VIEW IF EXISTS eventlibrariesused CASCADE;
CREATE VIEW eventlibrariesused AS
SELECT patron,code as library
FROM Patron,EventSignUp, allevents
WHERE Patron.card_number = EventSignUp.patron and allevents.event = EventSignUp.event;

--257 rows
DROP VIEW IF EXISTS booklibrariesused CASCADE;
CREATE VIEW booklibrariesused AS
SELECT patron,library
FROM Patron,Checkout
WHERE Patron.card_number = Checkout.patron;

--321
DROP VIEW IF EXISTS librariesused CASCADE;
CREATE VIEW librariesused AS
(SELECT patron,library FROM eventlibrariesused)
UNION
(SELECT patron,library FROM booklibrariesused);

DROP VIEW IF EXISTS bookschecked CASCADE;
CREATE VIEW bookschecked AS
SELECT patron,count(id) as books
FROM mypatron natural full join Checkout
GROUP BY patron;

DROP VIEW IF EXISTS eventswent CASCADE;
CREATE VIEW eventswent AS
SELECT patron,count(event) as events
FROM mypatron natural full join EventSignUp
GROUP BY patron;

DROP VIEW IF EXISTS avgevent CASCADE;
CREATE VIEW avgevent AS
SELECT distinct eventswent.patron,(SELECT avg(events) FROM eventlibrariesused natural join eventswent WHERE eventlibrariesused.library = ANY(SELECT library FROM librariesused l2 WHERE l1.patron = l2.patron)) as average
FROM eventswent natural join librariesused l1;

DROP VIEW IF EXISTS avgbooks CASCADE;
CREATE VIEW avgbooks AS
SELECT distinct bookschecked.patron,(SELECT avg(books) FROM booklibrariesused natural join bookschecked WHERE booklibrariesused.library = ANY(SELECT library FROM librariesused l2 WHERE l1.patron = l2.patron)) as average
FROM bookschecked natural join librariesused l1;


DROP VIEW IF EXISTS lowevent CASCADE;
CREATE VIEW lowevent AS
SELECT distinct eventswent.patron
FROM eventswent natural join avgevent
WHERE events<(0.25*average);

DROP VIEW IF EXISTS highevent CASCADE;
CREATE VIEW highevent AS
SELECT distinct eventswent.patron
FROM eventswent natural join avgevent
WHERE events>(0.75*average);

DROP VIEW IF EXISTS lowcheckout CASCADE;
CREATE VIEW lowcheckout AS
SELECT distinct bookschecked.patron
FROM bookschecked natural join avgbooks
WHERE books<(0.25*average);

DROP VIEW IF EXISTS highcheckout CASCADE;
CREATE VIEW highcheckout AS
SELECT distinct bookschecked.patron
FROM bookschecked natural join avgbooks
WHERE books>(0.75*average);

DROP VIEW IF EXISTS inactive CASCADE;
CREATE VIEW inactive AS
SELECT patron, 'inactive' as category
FROM lowcheckout NATURAL JOIN lowevent;

DROP VIEW IF EXISTS keener CASCADE;
CREATE VIEW keener AS
SELECT patron, 'keener' as category
FROM highcheckout NATURAL JOIN highevent;

DROP VIEW IF EXISTS reader CASCADE;
CREATE VIEW reader AS
SELECT patron, 'reader' as category
FROM highcheckout NATURAL JOIN lowevent;

DROP VIEW IF EXISTS doer CASCADE;
CREATE VIEW doer AS
SELECT patron, 'doer' as category
FROM lowcheckout NATURAL JOIN highevent;

DROP VIEW IF EXISTS categories CASCADE;
CREATE VIEW categories AS
(SELECT * FROM inactive) UNION (SELECT * FROM keener) UNION (SELECT * FROM reader) UNION (SELECT * FROM doer);

-- Your query that answers the question goes below the "insert into" line:
insert into q3
SELECT *
FROM categories natural full join mypatron;
