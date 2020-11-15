-- Devoted Fans

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q6 cascade;

CREATE TABLE q6 (
    patronID Char(20),
    devotedness INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS SoloBooks CASCADE;
CREATE VIEW SoloBooks AS
SELECT id, max(contributor) as contributor
FROM Holding JOIN HoldingContributor ON (Holding.id = HoldingContributor.holding)
WHERE htype = 'books'
GROUP BY id
HAVING count(contributor) = 1;

DROP VIEW IF EXISTS CheckedSolo CASCADE;
CREATE VIEW CheckedSolo AS
SELECT SoloBooks.id, contributor, patron
FROM SoloBooks JOIN Checkout ON (SoloBooks.id = Checkout.holding);

DROP VIEW IF EXISTS MatchCount CASCADE;
CREATE VIEW MatchCount AS
SELECT contributor, patron, count(*)
FROM checkedsolo
Group By contributor, patron;

DROP VIEW IF EXISTS NumSoloBooks CASCADE;
CREATE VIEW NumSoloBooks AS
select contributor, count(id)
FROM SoloBooks
GROUP BY contributor;

DROP VIEW IF EXISTS CheckoutMatch CASCADE;
CREATE VIEW CheckoutMatch AS
SELECT MatchCount.contributor, patron 
FROM MatchCount JOIN NumSoloBooks ON (MatchCount.contributor = NumSoloBooks.contributor)
WHERE (MatchCount.count >= NumSoloBooks.Count - 1
	OR (MatchCount.count = NumSoloBooks.Count AND NumSoloBooks.Count = 1));

DROP VIEW IF EXISTS ValidChecked CASCADE;
CREATE VIEW ValidChecked AS
SELECT *
FROM CheckedSolo
WHERE (contributor, patron) = ANY (SELECT * FROM CheckoutMatch);

DROP VIEW IF EXISTS FanCombos CASCADE;
CREATE VIEW FanCombos AS
SELECT contributor, ValidChecked.patron
FROM validchecked LEFT JOIN Review ON (validchecked.patron = Review.patron AND ValidChecked.id = Review.holding)
GROUP BY contributor, validchecked.patron
HAVING (count(id) = count(review) AND AVG(stars) >= 4);

DROP VIEW IF EXISTS Devotedness CASCADE;
CREATE VIEW Devotedness AS
SELECT patron.card_number as patronID, count(FanCombos.contributor) as devotedness
FROM patron LEFT JOIN FanCombos ON (patron.card_number = FanCombos.patron)
GROUP BY patron.card_number;

-- Your query that answers the question goes below the "insert into" line:
insert into q6
SELECT * FROM Devotedness;
