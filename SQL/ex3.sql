-- =====================================================================
-- SE3309 Assignment 3 - Item 3: three types of INSERT into Flight
-- Run on the fresh schema, right after ex2.sql and BEFORE the bulk load.
-- =====================================================================
USE flighttrack;

-- Setup only: the parent rows that Flight's foreign keys need.
INSERT INTO Airline VALUES ('AC', 'Air Canada', 'Canada');
INSERT INTO Airline VALUES ('WS', 'WestJet', 'Canada');
INSERT INTO Airport VALUES ('YYZ', 'Toronto Pearson International Airport', 'Toronto', 'Canada');
INSERT INTO Airport VALUES ('YXU', 'London International Airport', 'London', 'Canada');
INSERT INTO Airport VALUES ('YYC', 'Calgary International Airport', 'Calgary', 'Canada');

-- ---------------------------------------------------------------------
-- Type 1: positional INSERT. No column list, so one value for every
-- column, in the order the table was created.
-- ---------------------------------------------------------------------
INSERT INTO Flight
VALUES ('AC', 8275, DATE '2026-11-16', 'D31', '1', 'Arrived',
        TIMESTAMP '2026-11-16 08:10:00', TIMESTAMP '2026-11-16 08:22:00',
        TIMESTAMP '2026-11-16 08:55:00', TIMESTAMP '2026-11-16 09:04:00',
        'YYZ', 'YXU');

-- ---------------------------------------------------------------------
-- Type 2: INSERT with a column list, two rows in one statement.
-- Columns left out are filled by the schema: Status gets its DEFAULT
-- ('Scheduled'); Gate, Terminal and the actual times become NULL.
-- ---------------------------------------------------------------------
INSERT INTO Flight (AirlineCode, FlightNumber, FlightDate,
                    ScheduledDepartureTime, ScheduledArrivalTime,
                    DepartureAirportCode, ArrivalAirportCode)
VALUES ('AC', 8276, DATE '2026-11-16',
        TIMESTAMP '2026-11-16 17:40:00', TIMESTAMP '2026-11-16 18:25:00', 'YXU', 'YYZ'),
       ('WS', 512, DATE '2026-11-16',
        TIMESTAMP '2026-11-16 09:30:00', TIMESTAMP '2026-11-16 13:35:00', 'YXU', 'YYC');

-- ---------------------------------------------------------------------
-- Type 3: INSERT ... SELECT. Publish next week's Air Canada schedule by
-- copying every AC flight on 16 Nov seven days forward. The new rows
-- start clean: default status, no gate, no actual times.
-- ---------------------------------------------------------------------
INSERT INTO Flight (AirlineCode, FlightNumber, FlightDate, Terminal,
                    ScheduledDepartureTime, ScheduledArrivalTime,
                    DepartureAirportCode, ArrivalAirportCode)
SELECT AirlineCode, FlightNumber, FlightDate + INTERVAL '7' DAY, Terminal,
       ScheduledDepartureTime + INTERVAL '7' DAY,
       ScheduledArrivalTime + INTERVAL '7' DAY,
       DepartureAirportCode, ArrivalAirportCode
FROM Flight
WHERE AirlineCode = 'AC' AND FlightDate = DATE '2026-11-16';

-- The relation after the three INSERTs (5 rows)
SELECT * FROM Flight;
