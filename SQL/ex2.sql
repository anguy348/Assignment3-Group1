-- =====================================================================
-- SE3309 Assignment 3 - Item 2: FlightTrack schema
-- Run this file first. It rebuilds the whole schema from scratch.
-- =====================================================================

DROP SCHEMA IF EXISTS flighttrack;
CREATE SCHEMA flighttrack;
USE flighttrack;

-- ---------------------------------------------------------------------
-- Strong entities
-- ---------------------------------------------------------------------
CREATE TABLE Airline (
    AirlineCode  CHAR(2)      NOT NULL,          -- IATA code, e.g. 'AC'
    AirlineName  VARCHAR(60)  NOT NULL,
    Country      VARCHAR(50)  NOT NULL,
    PRIMARY KEY (AirlineCode),
    CONSTRAINT chk_airline_code CHECK (CHAR_LENGTH(AirlineCode) = 2)
);

CREATE TABLE Airport (
    AirportCode  CHAR(3)      NOT NULL,          -- IATA code, e.g. 'YXU'
    AirportName  VARCHAR(80)  NOT NULL,
    City         VARCHAR(50)  NOT NULL,
    Country      VARCHAR(50)  NOT NULL,
    PRIMARY KEY (AirportCode),
    CONSTRAINT chk_airport_code CHECK (CHAR_LENGTH(AirportCode) = 3)
);

CREATE TABLE User (
    UserID     INTEGER       NOT NULL,
    FirstName  VARCHAR(40)   NOT NULL,
    LastName   VARCHAR(40)   NOT NULL,
    Email      VARCHAR(100)  NOT NULL,
    Role       VARCHAR(10)   NOT NULL DEFAULT 'Regular',
    PRIMARY KEY (UserID),
    CONSTRAINT uq_user_email  UNIQUE (Email),                              -- alternate key
    CONSTRAINT chk_user_role  CHECK (Role IN ('Regular', 'Authorized')),
    CONSTRAINT chk_user_email CHECK (Email LIKE '%_@_%._%')
);

-- ---------------------------------------------------------------------
-- Flight: weak entity owned by Airline (a flight number is only unique
-- within its airline), so AirlineCode is part of the primary key.
-- ---------------------------------------------------------------------
CREATE TABLE Flight (
    AirlineCode             CHAR(2)      NOT NULL,
    FlightNumber            SMALLINT     NOT NULL,
    FlightDate              DATE         NOT NULL,
    Gate                    VARCHAR(5),                       -- unknown until assigned
    Terminal                VARCHAR(5),
    Status                  VARCHAR(10)  NOT NULL DEFAULT 'Scheduled',
    ScheduledDepartureTime  DATETIME     NOT NULL,
    ActualDepartureTime     DATETIME,                         -- NULL until it happens
    ScheduledArrivalTime    DATETIME     NOT NULL,
    ActualArrivalTime       DATETIME,
    DepartureAirportCode    CHAR(3)      NOT NULL,
    ArrivalAirportCode      CHAR(3)      NOT NULL,
    PRIMARY KEY (AirlineCode, FlightNumber, FlightDate),
    CONSTRAINT fk_flight_airline FOREIGN KEY (AirlineCode)
        REFERENCES Airline (AirlineCode)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    -- NO ACTION on update: MySQL will not allow a CHECK (chk_flight_route)
    -- on a column that a foreign key action could change.
    CONSTRAINT fk_flight_departure FOREIGN KEY (DepartureAirportCode)
        REFERENCES Airport (AirportCode)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_flight_arrival FOREIGN KEY (ArrivalAirportCode)
        REFERENCES Airport (AirportCode)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT chk_flight_number    CHECK (FlightNumber BETWEEN 1 AND 9999),
    CONSTRAINT chk_flight_status    CHECK (Status IN ('Scheduled', 'Boarding', 'Delayed',
                                                      'Departed', 'Arrived', 'Cancelled')),
    CONSTRAINT chk_flight_route     CHECK (DepartureAirportCode <> ArrivalAirportCode),
    CONSTRAINT chk_flight_date      CHECK (CAST(ScheduledDepartureTime AS DATE) = FlightDate),
    CONSTRAINT chk_flight_scheduled CHECK (ScheduledArrivalTime > ScheduledDepartureTime),
    CONSTRAINT chk_flight_actual    CHECK (ActualArrivalTime IS NULL
                                           OR (ActualDepartureTime IS NOT NULL
                                               AND ActualArrivalTime > ActualDepartureTime))
);

-- ---------------------------------------------------------------------
-- FlightStatusUpdate: weak entity owned by Flight (composition), so
-- deleting a flight deletes its update history.
-- ---------------------------------------------------------------------
CREATE TABLE FlightStatusUpdate (
    AirlineCode      CHAR(2)      NOT NULL,
    FlightNumber     SMALLINT     NOT NULL,
    FlightDate       DATE         NOT NULL,
    UpdateTime       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status           VARCHAR(10)  NOT NULL,
    UpdatedByUserID  INTEGER      NOT NULL,
    PRIMARY KEY (AirlineCode, FlightNumber, FlightDate, UpdateTime),
    CONSTRAINT fk_fsu_flight FOREIGN KEY (AirlineCode, FlightNumber, FlightDate)
        REFERENCES Flight (AirlineCode, FlightNumber, FlightDate)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_fsu_user FOREIGN KEY (UpdatedByUserID)
        REFERENCES User (UserID)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT chk_fsu_status CHECK (Status IN ('Scheduled', 'Boarding', 'Delayed',
                                                'Departed', 'Arrived', 'Cancelled'))
);

-- ---------------------------------------------------------------------
-- Tracks: the *:* relationship between User and Flight
-- ---------------------------------------------------------------------
CREATE TABLE Tracks (
    UserID                  INTEGER      NOT NULL,
    AirlineCode             CHAR(2)      NOT NULL,
    FlightNumber            SMALLINT     NOT NULL,
    FlightDate              DATE         NOT NULL,
    DateTracked             DATE         NOT NULL DEFAULT (CURRENT_DATE),
    NotificationPreference  VARCHAR(10)  NOT NULL DEFAULT 'Email',
    PRIMARY KEY (UserID, AirlineCode, FlightNumber, FlightDate),
    CONSTRAINT fk_tracks_user FOREIGN KEY (UserID)
        REFERENCES User (UserID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tracks_flight FOREIGN KEY (AirlineCode, FlightNumber, FlightDate)
        REFERENCES Flight (AirlineCode, FlightNumber, FlightDate)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_tracks_pref CHECK (NotificationPreference IN ('Email', 'SMS', 'Push', 'None'))
);

-- ---------------------------------------------------------------------
-- Indexes (primary keys and the UNIQUE email are indexed automatically)
-- ---------------------------------------------------------------------
CREATE INDEX idx_flight_departure ON Flight (DepartureAirportCode, FlightDate);  -- departures board
CREATE INDEX idx_flight_arrival   ON Flight (ArrivalAirportCode, FlightDate);    -- arrivals board
CREATE INDEX idx_flight_date      ON Flight (FlightDate);                        -- "all flights on a day"
CREATE INDEX idx_tracks_flight    ON Tracks (AirlineCode, FlightNumber, FlightDate);  -- who tracks this flight

-- ---------------------------------------------------------------------
-- Triggers: only Authorized users may post status updates. A CHECK
-- cannot look at another table, so this rule needs triggers.
-- ---------------------------------------------------------------------
DELIMITER //

CREATE TRIGGER trg_fsu_authorized_insert
BEFORE INSERT ON FlightStatusUpdate
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT * FROM User
                   WHERE UserID = NEW.UpdatedByUserID AND Role = 'Authorized') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only Authorized users can post flight status updates';
    END IF;
END//

CREATE TRIGGER trg_fsu_authorized_update
BEFORE UPDATE ON FlightStatusUpdate
FOR EACH ROW
BEGIN
    IF NEW.UpdatedByUserID <> OLD.UpdatedByUserID
       AND NOT EXISTS (SELECT * FROM User
                       WHERE UserID = NEW.UpdatedByUserID AND Role = 'Authorized') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only Authorized users can post flight status updates';
    END IF;
END//

DELIMITER ;

-- ---------------------------------------------------------------------
-- Show the resulting relation schemas
-- ---------------------------------------------------------------------
DESCRIBE Airline;
DESCRIBE Airport;
DESCRIBE User;
DESCRIBE Flight;
DESCRIBE FlightStatusUpdate;
DESCRIBE Tracks;
