-- =====================================================================
-- SE3309 Assignment 3 - Item 5: seven queries
-- Run after the bulk load. The data's "present" is 15 Nov 2026, 12:00.
-- =====================================================================
USE flighttrack;

-- ---------------------------------------------------------------------
-- Q1 (plain SELECT-FROM-WHERE): flight search by route and date range.
-- Toronto to Calgary, 14-16 Nov.
-- ---------------------------------------------------------------------
SELECT AirlineCode, FlightNumber, FlightDate, ScheduledDepartureTime,
       ScheduledArrivalTime, Gate, Status
FROM Flight
WHERE DepartureAirportCode = 'YYZ'
  AND ArrivalAirportCode = 'YYC'
  AND FlightDate BETWEEN DATE '2026-11-14' AND DATE '2026-11-16'
ORDER BY ScheduledDepartureTime;

-- ---------------------------------------------------------------------
-- Q2 (join over five tables, Airport used twice under role names):
-- "my tracked flights" page for user 134, codes replaced by names.
-- ---------------------------------------------------------------------
SELECT al.AirlineName, f.FlightNumber, f.FlightDate,
       dep.City AS FromCity, arr.City AS ToCity,
       f.ScheduledDepartureTime, f.Status, t.NotificationPreference
FROM Tracks t
     JOIN Flight f    ON f.AirlineCode = t.AirlineCode
                     AND f.FlightNumber = t.FlightNumber
                     AND f.FlightDate = t.FlightDate
     JOIN Airline al  ON al.AirlineCode = f.AirlineCode
     JOIN Airport dep ON dep.AirportCode = f.DepartureAirportCode
     JOIN Airport arr ON arr.AirportCode = f.ArrivalAirportCode
WHERE t.UserID = 134
ORDER BY f.ScheduledDepartureTime;

-- ---------------------------------------------------------------------
-- Q3 (aggregates with GROUP BY and HAVING): departure delay statistics
-- per airport, for airports with at least 100 departed flights.
-- Delay is derived (actual - scheduled), never stored.
-- ---------------------------------------------------------------------
SELECT f.DepartureAirportCode, a.City,
       COUNT(*) AS Departures,
       CAST(AVG(TIMESTAMPDIFF(MINUTE, f.ScheduledDepartureTime, f.ActualDepartureTime))
            AS DECIMAL(6,1)) AS AvgDelayMin,
       MAX(TIMESTAMPDIFF(MINUTE, f.ScheduledDepartureTime, f.ActualDepartureTime)) AS WorstDelayMin
FROM Flight f
     JOIN Airport a ON a.AirportCode = f.DepartureAirportCode
WHERE f.ActualDepartureTime IS NOT NULL
GROUP BY f.DepartureAirportCode, a.City
HAVING COUNT(*) >= 100
ORDER BY AvgDelayMin DESC;

-- ---------------------------------------------------------------------
-- Q4 (correlated subquery with EXISTS): who needs an alert? Users
-- tracking, with notifications on, a flight that was reported Delayed
-- or Cancelled today. EXISTS lists each user once even if several of
-- their flights are affected.
-- ---------------------------------------------------------------------
SELECT u.UserID, u.FirstName, u.LastName, u.Email
FROM User u
WHERE EXISTS (SELECT *
              FROM Tracks t
                   JOIN FlightStatusUpdate s ON s.AirlineCode = t.AirlineCode
                                            AND s.FlightNumber = t.FlightNumber
                                            AND s.FlightDate = t.FlightDate
              WHERE t.UserID = u.UserID
                AND t.NotificationPreference <> 'None'
                AND s.Status IN ('Delayed', 'Cancelled')
                AND s.UpdateTime >= TIMESTAMP '2026-11-15 00:00:00')
ORDER BY u.UserID;

-- ---------------------------------------------------------------------
-- Q5 (nested aggregate with >= ALL): the most-tracked flight. The
-- subquery returns every flight's tracker count; the outer HAVING keeps
-- the group(s) whose count is at least as large as all of them.
-- ---------------------------------------------------------------------
SELECT AirlineCode, FlightNumber, FlightDate, COUNT(*) AS Trackers
FROM Tracks
GROUP BY AirlineCode, FlightNumber, FlightDate
HAVING COUNT(*) >= ALL (SELECT COUNT(*)
                        FROM Tracks
                        GROUP BY AirlineCode, FlightNumber, FlightDate);

-- ---------------------------------------------------------------------
-- Q6 (LEFT OUTER JOIN): cancellations per airline for 8-14 Nov,
-- keeping airlines that had none. The filter sits in ON, not WHERE, so
-- airlines without a match survive with a count of 0.
-- ---------------------------------------------------------------------
SELECT a.AirlineCode, a.AirlineName, COUNT(f.FlightNumber) AS Cancellations
FROM Airline a
     LEFT OUTER JOIN Flight f ON f.AirlineCode = a.AirlineCode
                             AND f.Status = 'Cancelled'
                             AND f.FlightDate BETWEEN DATE '2026-11-08' AND DATE '2026-11-14'
GROUP BY a.AirlineCode, a.AirlineName
ORDER BY Cancellations DESC, a.AirlineCode;

-- ---------------------------------------------------------------------
-- Q7 (UNION): London (YXU) airport board for 15 Nov, departures and
-- arrivals in one list, each row showing the city at the other end.
-- ---------------------------------------------------------------------
SELECT 'Departure' AS Movement, f.AirlineCode, f.FlightNumber,
       a.City AS OtherCity, f.ScheduledDepartureTime AS ScheduledTime, f.Status
FROM Flight f
     JOIN Airport a ON a.AirportCode = f.ArrivalAirportCode
WHERE f.DepartureAirportCode = 'YXU'
  AND f.FlightDate = DATE '2026-11-15'
UNION
SELECT 'Arrival', f.AirlineCode, f.FlightNumber,
       a.City, f.ScheduledArrivalTime, f.Status
FROM Flight f
     JOIN Airport a ON a.AirportCode = f.DepartureAirportCode
WHERE f.ArrivalAirportCode = 'YXU'
  AND CAST(f.ScheduledArrivalTime AS DATE) = DATE '2026-11-15'
ORDER BY ScheduledTime;
