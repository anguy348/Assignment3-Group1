"""
SE3309 Assignment 3 - Item 4: FlightTrack data generator

Fabricates data for all six relations and writes it to load_data.sql (in the
same folder) as batched INSERT statements, parents before children.

    python generate_data.py          # writes load_data.sql
    then run load_data.sql in MySQL Workbench (File > Run SQL Script)

How joinability and key uniqueness are guaranteed:
  * Parents are generated first and every foreign key value is picked from
    rows that already exist (flights from the airline/airport lists, status
    updates and tracks from the generated flights and users).
  * Keys cannot repeat: user IDs are sequential, a flight is one schedule on
    one day, update times strictly increase within a flight, and tracks are
    collected in a dictionary keyed on (user, flight).

Only the standard library is used and the seed is fixed, so every run
produces exactly the same file.
"""
import random
from datetime import date, datetime, time, timedelta
from math import asin, cos, radians, sin, sqrt
from pathlib import Path

random.seed(3309)

NOW = datetime(2026, 11, 15, 12, 0)                 # the simulated "present"
FIRST_DAY, LAST_DAY = date(2026, 10, 15), date(2026, 11, 30)
N_USERS, N_STAFF, N_IDLE_STAFF = 600, 30, 3         # users 1..30 are Authorized
N_TRACKS = 4000
CANCEL_PCT = 3

# code, name, country, hub, destinations served from the hub
AIRLINES = [
    ("AC", "Air Canada", "Canada", "YYZ",
     ["YXU", "YUL", "YOW", "YVR", "YYC", "YHZ", "LGA", "LAX", "LHR", "NRT"]),
    ("WS", "WestJet", "Canada", "YYC", ["YXU", "YYZ", "YVR", "YEG", "YWG", "LAS"]),
    ("PD", "Porter Airlines", "Canada", "YTZ", ["YOW", "YUL", "YHZ", "EWR"]),
    ("TS", "Air Transat", "Canada", "YUL", ["CUN", "CDG"]),
    ("F8", "Flair Airlines", "Canada", "YEG", ["YVR", "YYZ"]),
    ("AA", "American Airlines", "United States", "DFW", ["YYZ", "MIA"]),
    ("DL", "Delta Air Lines", "United States", "ATL", ["YYZ", "JFK"]),
    ("UA", "United Airlines", "United States", "ORD", ["YYZ", "SFO"]),
    ("B6", "JetBlue Airways", "United States", "JFK", ["BOS", "MCO"]),
    ("BA", "British Airways", "United Kingdom", "LHR", ["YYZ", "YVR"]),
    ("AF", "Air France", "France", "CDG", ["YUL"]),
    ("LH", "Lufthansa", "Germany", "FRA", ["YYZ"]),
    ("KL", "KLM Royal Dutch Airlines", "Netherlands", "AMS", ["YYZ"]),
    ("NH", "All Nippon Airways", "Japan", "NRT", ["YVR"]),
    ("EK", "Emirates", "United Arab Emirates", "DXB", ["YYZ"]),
]

# code, name, city, country, latitude, longitude (coordinates only set flight times)
AIRPORTS = [
    ("YYZ", "Toronto Pearson International Airport", "Toronto", "Canada", 43.68, -79.63),
    ("YTZ", "Billy Bishop Toronto City Airport", "Toronto", "Canada", 43.63, -79.40),
    ("YXU", "London International Airport", "London", "Canada", 43.03, -81.15),
    ("YUL", "Montreal-Trudeau International Airport", "Montreal", "Canada", 45.47, -73.74),
    ("YOW", "Ottawa Macdonald-Cartier International Airport", "Ottawa", "Canada", 45.32, -75.67),
    ("YQB", "Quebec City Jean Lesage International Airport", "Quebec City", "Canada", 46.79, -71.39),
    ("YHZ", "Halifax Stanfield International Airport", "Halifax", "Canada", 44.88, -63.51),
    ("YWG", "Winnipeg Richardson International Airport", "Winnipeg", "Canada", 49.91, -97.24),
    ("YYC", "Calgary International Airport", "Calgary", "Canada", 51.13, -114.01),
    ("YEG", "Edmonton International Airport", "Edmonton", "Canada", 53.31, -113.58),
    ("YVR", "Vancouver International Airport", "Vancouver", "Canada", 49.19, -123.18),
    ("YYJ", "Victoria International Airport", "Victoria", "Canada", 48.65, -123.43),
    ("JFK", "John F. Kennedy International Airport", "New York", "United States", 40.64, -73.78),
    ("LGA", "LaGuardia Airport", "New York", "United States", 40.78, -73.87),
    ("EWR", "Newark Liberty International Airport", "Newark", "United States", 40.69, -74.17),
    ("BOS", "Boston Logan International Airport", "Boston", "United States", 42.36, -71.01),
    ("ORD", "Chicago O'Hare International Airport", "Chicago", "United States", 41.98, -87.90),
    ("ATL", "Hartsfield-Jackson Atlanta International Airport", "Atlanta", "United States", 33.64, -84.43),
    ("DFW", "Dallas/Fort Worth International Airport", "Dallas", "United States", 32.90, -97.04),
    ("DEN", "Denver International Airport", "Denver", "United States", 39.86, -104.67),
    ("LAX", "Los Angeles International Airport", "Los Angeles", "United States", 33.94, -118.41),
    ("SFO", "San Francisco International Airport", "San Francisco", "United States", 37.62, -122.38),
    ("SEA", "Seattle-Tacoma International Airport", "Seattle", "United States", 47.45, -122.31),
    ("MIA", "Miami International Airport", "Miami", "United States", 25.79, -80.29),
    ("MCO", "Orlando International Airport", "Orlando", "United States", 28.43, -81.31),
    ("LAS", "Harry Reid International Airport", "Las Vegas", "United States", 36.08, -115.15),
    ("DTW", "Detroit Metropolitan Airport", "Detroit", "United States", 42.21, -83.35),
    ("LHR", "London Heathrow Airport", "London", "United Kingdom", 51.47, -0.45),
    ("CDG", "Paris Charles de Gaulle Airport", "Paris", "France", 49.01, 2.55),
    ("AMS", "Amsterdam Airport Schiphol", "Amsterdam", "Netherlands", 52.31, 4.76),
    ("FRA", "Frankfurt Airport", "Frankfurt", "Germany", 50.04, 8.56),
    ("DUB", "Dublin Airport", "Dublin", "Ireland", 53.43, -6.25),
    ("MAD", "Adolfo Suarez Madrid-Barajas Airport", "Madrid", "Spain", 40.49, -3.57),
    ("FCO", "Rome Fiumicino Airport", "Rome", "Italy", 41.80, 12.25),
    ("NRT", "Narita International Airport", "Tokyo", "Japan", 35.77, 140.39),
    ("ICN", "Incheon International Airport", "Seoul", "South Korea", 37.46, 126.44),
    ("SIN", "Singapore Changi Airport", "Singapore", "Singapore", 1.36, 103.99),
    ("DXB", "Dubai International Airport", "Dubai", "United Arab Emirates", 25.25, 55.36),
    ("SYD", "Sydney Kingsford Smith Airport", "Sydney", "Australia", -33.95, 151.18),
    ("CUN", "Cancun International Airport", "Cancun", "Mexico", 21.04, -86.87),
]

FIRST_NAMES = ["Liam", "Olivia", "Noah", "Emma", "Lucas", "Ava", "Ethan", "Sophia", "Mason", "Mia",
               "Logan", "Chloe", "Daniel", "Emily", "Aiden", "Grace", "Owen", "Hannah", "Caleb", "Zoe",
               "Arjun", "Priya", "Wei", "Mei", "Omar", "Layla", "Mateo", "Sofia", "Kenji", "Yuki",
               "Tariq", "Amara", "Diego", "Elena", "Ivan", "Nadia", "Samuel", "Ruth", "Felix", "Clara"]
LAST_NAMES = ["Smith", "Brown", "Tremblay", "Martin", "Roy", "Wilson", "MacDonald", "Gagnon", "Johnson",
              "Taylor", "Campbell", "Anderson", "Lee", "Wong", "Singh", "Patel", "Chen", "Kim", "Garcia",
              "Khan", "Ali", "Morin", "Scott", "Reid", "Murphy", "Clark", "Young", "Hill", "Walker",
              "Evans", "Hughes", "Baker", "Fraser", "Grant", "Boucher", "Lavoie", "Ito", "Sato",
              "Haddad", "Okafor"]

# Departure delay in minutes: (low, high) buckets, and three airline "personalities"
DELAY_BUCKETS = [(-5, 14), (15, 44), (45, 119), (120, 300)]
DELAY_PROFILES = [(80, 13, 5, 2), (72, 17, 8, 3), (58, 24, 13, 5)]
PREFERENCES, PREFERENCE_WEIGHTS = ["Email", "Push", "SMS", "None"], [50, 30, 15, 5]


def flight_minutes(origin, destination):
    """Scheduled duration from great-circle distance: 810 km/h plus 30 min on the ground."""
    lat1, lon1, lat2, lon2 = map(radians, COORDS[origin] + COORDS[destination])
    a = sin((lat2 - lat1) / 2) ** 2 + cos(lat1) * cos(lat2) * sin((lon2 - lon1) / 2) ** 2
    km = 2 * 6371 * asin(sqrt(a))
    return 5 * round((km / 13.5 + 30) / 5)


def literal(value):
    """Python value -> SQL literal."""
    if value is None:
        return "NULL"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, datetime):
        return "'" + value.strftime("%Y-%m-%d %H:%M:%S") + "'"
    if isinstance(value, date):
        return "'" + value.isoformat() + "'"
    return "'" + str(value).replace("'", "''") + "'"


def write_inserts(out, table, columns, rows, batch=500):
    """One multi-row INSERT per 500 rows keeps the load fast."""
    for start in range(0, len(rows), batch):
        out.write(f"INSERT INTO {table} ({', '.join(columns)}) VALUES\n")
        out.write(",\n".join("(" + ", ".join(literal(v) for v in row) + ")"
                             for row in rows[start:start + batch]))
        out.write(";\n")


COORDS = {code: (lat, lon) for code, _, _, _, lat, lon in AIRPORTS}

# ---- User: sequential IDs; the first N_STAFF are Authorized ----------------------------
users = []
for user_id in range(1, N_USERS + 1):
    first, last = random.choice(FIRST_NAMES), random.choice(LAST_NAMES)
    staff = user_id <= N_STAFF
    domain = "flighttrack.example" if staff else random.choice(["example.com", "example.org", "example.net"])
    users.append((user_id, first, last, f"{first}.{last}{user_id}@{domain}".lower(),
                  "Authorized" if staff else "Regular"))
active_staff = list(range(1, N_STAFF - N_IDLE_STAFF + 1))   # the last few staff never post

# ---- Schedules: every route is flown out and back once a day ----------------------------
schedules = []          # (airline, flight number, origin, destination, departure minute, duration)
delay_profile = {}
for code, _, _, hub, destinations in AIRLINES:
    delay_profile[code] = random.choice(DELAY_PROFILES)
    numbers = random.sample(range(100, 1000, 2), len(destinations))     # unique within the airline
    for number, destination in zip(numbers, destinations):
        duration = flight_minutes(hub, destination)
        schedules.append((code, number, hub, destination, random.randrange(300, 1380, 5), duration))
        schedules.append((code, number + 1, destination, hub, random.randrange(300, 1380, 5), duration))

# ---- Flight and FlightStatusUpdate: one flight per schedule per day ---------------------
flights, updates, terminals = [], [], {}
day = FIRST_DAY
while day <= LAST_DAY:
    for code, number, origin, destination, minute, duration in schedules:
        sched_dep = datetime.combine(day, time()) + timedelta(minutes=minute)
        sched_arr = sched_dep + timedelta(minutes=duration)
        low, high = random.choices(DELAY_BUCKETS, delay_profile[code])[0]
        delay = random.randint(low, high)
        actual_dep = sched_dep + timedelta(minutes=delay)
        actual_arr = sched_arr + timedelta(minutes=delay + random.randint(-15, 20))
        gate = random.choice("ABCDE") + str(random.randint(1, 40))
        terminal = terminals.setdefault((code, origin), str(random.randint(1, 3)))
        cancelled = sched_dep <= NOW and random.randrange(100) < CANCEL_PCT

        # The flight's life story as (time, status) events ...
        if cancelled:
            events = [(sched_dep - timedelta(minutes=random.randint(30, 240)), "Cancelled")]
        else:
            events = [(sched_dep - timedelta(minutes=45), "Delayed")] if delay >= 15 else []
            events += [(actual_dep - timedelta(minutes=35), "Boarding"),
                       (actual_dep, "Departed"), (actual_arr, "Arrived")]
        # ... of which only the part before NOW has happened. The last event that has
        # happened is the flight's current status, so Flight.Status always agrees
        # with the newest FlightStatusUpdate row.
        events = [event for event in events if event[0] <= NOW]
        status = events[-1][1] if events else "Scheduled"

        flights.append((code, number, day,
                        gate if sched_dep <= NOW + timedelta(hours=24) and status != "Cancelled"
                        else None,                   # assigned a day ahead, released on cancellation
                        terminal, status, sched_dep,
                        actual_dep if status in ("Departed", "Arrived") else None,
                        sched_arr,
                        actual_arr if status == "Arrived" else None,
                        origin, destination))
        for when, new_status in events:
            updates.append((code, number, day, when, new_status, random.choice(active_staff)))
    day += timedelta(days=1)

# ---- Tracks: random (user, flight) pairs, no duplicates ---------------------------------
user_ids = [u[0] for u in users]
random.shuffle(user_ids)
trackers = user_ids[:N_USERS * 85 // 100]                    # 15% of users track nothing
tracker_weights = [random.randint(1, 10) for _ in trackers]  # some users are frequent flyers
flight_weights = [3 if abs((f[2] - NOW.date()).days) <= 10 else 1 for f in flights]   # current flights are popular
picked_users = random.choices(trackers, tracker_weights, k=2 * N_TRACKS)
picked_flights = random.choices(flights, flight_weights, k=2 * N_TRACKS)
tracks = {}
for user_id, flight in zip(picked_users, picked_flights):
    key = (user_id, flight[0], flight[1], flight[2])
    if key in tracks or len(tracks) == N_TRACKS:
        continue
    tracked_on = min(flight[2] - timedelta(days=random.randint(0, 14)), NOW.date())
    tracks[key] = (tracked_on, random.choices(PREFERENCES, PREFERENCE_WEIGHTS)[0])
track_rows = sorted(key + value for key, value in tracks.items())

# ---- Write the load script -------------------------------------------------------------
output = Path(__file__).with_name("load_data.sql")
with open(output, "w", encoding="utf-8", newline="\n") as out:
    out.write("-- Generated by generate_data.py (seed 3309). Do not edit by hand.\n")
    out.write("USE flighttrack;\n")
    out.write("SET SQL_SAFE_UPDATES = 0;   -- lets Workbench run the DELETEs below\n")
    for table in ["Tracks", "FlightStatusUpdate", "Flight", "User", "Airport", "Airline"]:
        out.write(f"DELETE FROM {table};\n")                 # children first, so the script can be re-run
    write_inserts(out, "Airline", ["AirlineCode", "AirlineName", "Country"],
                  [a[:3] for a in AIRLINES])
    write_inserts(out, "Airport", ["AirportCode", "AirportName", "City", "Country"],
                  [a[:4] for a in AIRPORTS])
    write_inserts(out, "User", ["UserID", "FirstName", "LastName", "Email", "Role"], users)
    write_inserts(out, "Flight",
                  ["AirlineCode", "FlightNumber", "FlightDate", "Gate", "Terminal", "Status",
                   "ScheduledDepartureTime", "ActualDepartureTime", "ScheduledArrivalTime",
                   "ActualArrivalTime", "DepartureAirportCode", "ArrivalAirportCode"], flights)
    write_inserts(out, "FlightStatusUpdate",
                  ["AirlineCode", "FlightNumber", "FlightDate", "UpdateTime", "Status",
                   "UpdatedByUserID"], updates)
    write_inserts(out, "Tracks",
                  ["UserID", "AirlineCode", "FlightNumber", "FlightDate", "DateTracked",
                   "NotificationPreference"], track_rows)

print(f"Wrote {output.name}: {len(AIRLINES)} airlines, {len(AIRPORTS)} airports, {len(users)} users, "
      f"{len(flights)} flights, {len(updates)} status updates, {len(track_rows)} tracks")
