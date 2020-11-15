-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- You might find this helpful for solving update 1:
-- A mapping between the day of the week and its index
DROP VIEW IF EXISTS day_of_week CASCADE;
CREATE VIEW day_of_week (day, idx) AS
SELECT * FROM (
	VALUES ('sun', 0), ('mon', 1), ('tue', 2), ('wed', 3),
	       ('thu', 4), ('fri', 5), ('sat', 6)
) AS d(day, idx);


-- Define views for your intermediate steps here, and end with a
-- INSERT, DELETE, or UPDATE statement.

DROP VIEW IF EXISTS RoomHoursString CASCADE;
CREATE VIEW RoomHoursString AS
SELECT id as room, day, start_time, end_time
FROM LibraryRoom JOIN LibraryHours
ON (LibraryRoom.library = LibraryHours.library);

DROP VIEW IF EXISTS RoomHours CASCADE;
CREATE VIEW RoomHours AS
SELECT room, idx as day, start_time, end_time
FROM RoomHoursString JOIN day_of_week
ON (RoomHoursString.day::varchar(3) = day_of_week.day::varchar(3));

DROP VIEW IF EXISTS EventHours CASCADE;
CREATE VIEW EventHours AS
SELECT event, edate, room, EXTRACT(dow from edate) as day, start_time, end_time
FROM LibraryEvent JOIN EventSchedule
ON (LibraryEvent.id = EventSchedule.event);

DROP VIEW IF EXISTS OutOfBounds CASCADE;
CREATE VIEW OutOfBounds AS
SELECT event, edate
FROM RoomHours join EventHours
ON (RoomHours.room = EventHours.room and RoomHours.day = EventHours.day)
WHERE (EventHours.start_time < RoomHours.start_time
	OR EventHours.end_time > RoomHours.end_time);

-- remove event instances that are out of bounds
DELETE FROM EventSchedule
WHERE (EventSchedule.event, EventSchedule.edate) = ANY(
	SELECT event, edate FROM OutOfBounds);

-- remove any registrations for a deleted event
-- remove event if it is no longer scheduled at all
DROP VIEW IF EXISTS NotScheduled CASCADE;
CREATE VIEW NotScheduled AS
SELECT id
FROM LibraryEvent
WHERE id NOT IN (SELECT event as id FROM EventSchedule);

DELETE FROM EventSignUp
WHERE EventSignUp.event = ANY(SELECT id FROM NotScheduled);

DELETE FROM LibraryEvent
WHERE LibraryEvent.id = ANY(SELECT id FROM NotScheduled);
