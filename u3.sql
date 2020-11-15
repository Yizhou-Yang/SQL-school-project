-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here, and end with a
-- INSERT, DELETE, or UPDATE statement.

DROP VIEW IF EXISTS OpenSunday CASCADE;
CREATE VIEW OpenSunday AS
SELECT library
FROM LibraryHours
WHERE day = 'sun';

DROP VIEW IF EXISTS LateWeekday CASCADE;
CREATE VIEW LateWeekday AS
SELECT distinct library
FROM LibraryHours
WHERE day IN ('mon', 'tue', 'wed', 'thu', 'fri')
AND end_time > time '18:00:00';

DROP VIEW IF EXISTS BusinessHoursOnly CASCADE;
CREATE VIEW BusinessHoursOnly AS
SELECT code as library
FROM LibraryBranch
WHERE code NOT IN (SELECT library FROM LateWeekday)
AND code NOT IN (SELECT library from OpenSunday);

-- if library is open thursday extend closing
UPDATE LibraryHours SET end_time = time '21:00:00'
FROM BusinessHoursOnly
WHERE LibraryHours.library = BusinessHoursOnly.library
AND LibraryHours.day = 'thu';

-- if library is not open thursday open it from 6-9pm
INSERT INTO LibraryHours (library, day, start_time, end_time)
       	SELECT library, 'thu', time '18:00:00', time '21:00:00'
	FROM BusinessHoursOnly
	WHERE NOT EXISTS (SELECT * FROM LibraryHours
		WHERE LibraryHours.library = BusinessHoursOnly.library);
