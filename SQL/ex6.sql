-- =====================================================================
-- SE3309 Assignment 3 - Item 6: three data modification commands
-- Scenario: a snowstorm is forecast for Toronto, so on 15 Nov at 12:30
-- every flight in or out of YYZ on 16 Nov is cancelled in advance.
-- =====================================================================
USE flighttrack;

-- Workbench setting, not part of the three commands: its "safe updates"
-- mode rejects any UPDATE or DELETE whose WHERE does not use a key.
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

-- ---------------------------------------------------------------------
-- M1: INSERT the result of a query. One 'Cancelled' status update for
-- each affected flight that has not left yet, posted by staff user 1.
-- (trg_fsu_authorized_insert checks user 1 for every row inserted.)
-- ---------------------------------------------------------------------
INSERT INTO FlightStatusUpdate (AirlineCode, FlightNumber, FlightDate,
                                UpdateTime, Status, UpdatedByUserID)
SELECT f.AirlineCode, f.FlightNumber, f.FlightDate,
       TIMESTAMP '2026-11-15 12:30:00', 'Cancelled', 1
FROM Flight f
WHERE f.FlightDate = DATE '2026-11-16'
  AND (f.DepartureAirportCode = 'YYZ' OR f.ArrivalAirportCode = 'YYZ')
  AND f.Status IN ('Scheduled', 'Delayed');

-- ---------------------------------------------------------------------
-- M2: UPDATE several tuples at once. Flight.Status is a cached copy of
-- the newest status update, so bring it back in line with the log:
-- every flight that has a 'Cancelled' update but is not marked
-- cancelled yet gets cancelled and gives up its gate.
-- ---------------------------------------------------------------------
UPDATE Flight
SET Status = 'Cancelled',
    Gate = NULL
WHERE Status <> 'Cancelled'
  AND EXISTS (SELECT *
              FROM FlightStatusUpdate s
              WHERE s.AirlineCode = Flight.AirlineCode
                AND s.FlightNumber = Flight.FlightNumber
                AND s.FlightDate = Flight.FlightDate
                AND s.Status = 'Cancelled');

COMMIT;   -- M1 and M2 succeed or fail together, so the log and the cache cannot disagree

-- ---------------------------------------------------------------------
-- M3: DELETE a subset of tuples. Housekeeping: drop the tracking
-- subscriptions on flights that were cancelled back in October, since
-- nothing more can happen to those flights.
-- ---------------------------------------------------------------------
DELETE FROM Tracks
WHERE EXISTS (SELECT *
              FROM Flight f
              WHERE f.AirlineCode = Tracks.AirlineCode
                AND f.FlightNumber = Tracks.FlightNumber
                AND f.FlightDate = Tracks.FlightDate
                AND f.Status = 'Cancelled'
                AND f.FlightDate < DATE '2026-11-01');

-- Check: the storm day at YYZ after M1 and M2
SELECT Status, COUNT(*) AS Flights
FROM Flight
WHERE FlightDate = DATE '2026-11-16'
  AND (DepartureAirportCode = 'YYZ' OR ArrivalAirportCode = 'YYZ')
GROUP BY Status;
