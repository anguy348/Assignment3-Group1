-- =====================================================================
-- SE3309 Assignment 3 - Item 7: two views
-- Run statements one at a time (Ctrl+Enter) or turn on "continue on
-- error": four of the modification attempts below are SUPPOSED to fail.
-- =====================================================================
USE flighttrack;

DROP VIEW IF EXISTS AirlinePerformance;
DROP VIEW IF EXISTS StaffMember;

-- ---------------------------------------------------------------------
-- View 1: on-time performance per airline (the Flight Delay Statistics
-- feature). Delay is derived from the two departure times. "On time"
-- means less than 15 minutes late, the usual industry cut-off.
-- ---------------------------------------------------------------------
CREATE VIEW AirlinePerformance (AirlineCode, AirlineName, DepartedFlights,
                                AvgDelayMin, OnTimePct) AS
SELECT a.AirlineCode, a.AirlineName, COUNT(*),
       CAST(AVG(TIMESTAMPDIFF(MINUTE, f.ScheduledDepartureTime, f.ActualDepartureTime))
            AS DECIMAL(6,1)),
       CAST(100 * AVG(CASE WHEN TIMESTAMPDIFF(MINUTE, f.ScheduledDepartureTime,
                                              f.ActualDepartureTime) < 15
                           THEN 1 ELSE 0 END)
            AS DECIMAL(5,1))
FROM Airline a
     JOIN Flight f ON f.AirlineCode = a.AirlineCode
WHERE f.ActualDepartureTime IS NOT NULL
GROUP BY a.AirlineCode, a.AirlineName;

-- Query on view 1: airlines that leave on time less than 75% of the time
SELECT *
FROM AirlinePerformance
WHERE OnTimePct < 75
ORDER BY OnTimePct;

-- Modification attempts on view 1 (both fail: the view is not updatable)
INSERT INTO AirlinePerformance
VALUES ('ZZ', 'Test Air', 10, 0.0, 100.0);

UPDATE AirlinePerformance
SET AvgDelayMin = 0
WHERE AirlineCode = 'WS';

-- ---------------------------------------------------------------------
-- View 2: staff members only (Authorized users). WITH CHECK OPTION stops
-- anyone from adding or changing a row through the view so that it
-- would no longer belong in the view.
-- ---------------------------------------------------------------------
CREATE VIEW StaffMember AS
SELECT UserID, FirstName, LastName, Email, Role
FROM User
WHERE Role = 'Authorized'
WITH CHECK OPTION;

-- Query on view 2: staff accounts that have never posted a status update
SELECT s.UserID, s.FirstName, s.LastName, s.Email
FROM StaffMember s
WHERE NOT EXISTS (SELECT *
                  FROM FlightStatusUpdate u
                  WHERE u.UpdatedByUserID = s.UserID)
ORDER BY s.UserID;

-- Modification attempts on view 2
-- (a) succeeds: the new row satisfies Role = 'Authorized' and lands in User
INSERT INTO StaffMember
VALUES (601, 'Dana', 'Okafor', 'dana.okafor601@flighttrack.example', 'Authorized');
SELECT * FROM User WHERE UserID = 601;

-- (b) fails: a Regular user would vanish from the view (CHECK OPTION)
INSERT INTO StaffMember
VALUES (602, 'Sam', 'Reid', 'sam.reid602@example.com', 'Regular');

-- (c) fails: demoting a staff member through the view (CHECK OPTION)
UPDATE StaffMember
SET Role = 'Regular'
WHERE UserID = 601;

-- (d) succeeds: deleting through the view removes the row from User
DELETE FROM StaffMember
WHERE UserID = 601;
SELECT COUNT(*) AS StillThere FROM User WHERE UserID = 601;
