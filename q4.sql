-- Explorers Contest

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q4 cascade;

CREATE TABLE q4 (
    patronID CHAR(20)
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS IDWard CASCADE;
CREATE VIEW IDWard AS
SELECT libraryevent.id, ward
FROM (LibraryRoom JOIN LibraryBranch ON (LibraryRoom.library = LibraryBranch.code)) AS LRoomExpanded
JOIN LibraryEvent ON (LibraryEvent.room = LRoomExpanded.id);

DROP VIEW IF EXISTS IDWardEdate CASCADE;
CREATE VIEW IDWardEdate AS
SELECT id, ward, date_part('year', edate) as year
FROM IDWard JOIN EventSchedule ON (IDWard.id = EventSchedule.event);

DROP VIEW IF EXISTS Attendance CASCADE;
CREATE VIEW Attendance AS
SELECT patron, ward, year
FROM IDWardedate JOIN EventSignUp ON (IDWardEdate.id = EventSignUp.event);

DROP VIEW IF EXISTS Explorers CASCADE;
CREATE VIEW Explorers AS
SELECT distinct patron as patronID
FROM (SELECT distinct patron, year FROM Attendance) PY
WHERE NOT EXISTS (SELECT distinct id
	FROM ward
	WHERE NOT EXISTS (SELECT * FROM (
		SELECT * FROM Attendance
		WHERE (PY.year = Attendance.year
			AND PY.patron = Attendance.patron
			AND ward.id = Attendance.ward)
		) MissingWard));

-- Your query that answers the question goes below the "insert into" line:
insert into q4
SELECT * FROM Explorers;
