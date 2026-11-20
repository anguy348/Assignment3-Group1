# Assignment3-Group1 # SE 3309 Assignment 3 – FlightTrack Database (Group 1)

Taige Zhang, Yining Wang, Raphael Cecil Chong, Zishun Shen, Anthony Nguyen

## Folders
- **DESC** – report (PDF): explanations, queries and screenshots for Items 2–7
- **SQL** – ex2.sql (schema), ex3.sql (INSERTs), ex5.sql (queries), ex6.sql (modifications), ex7.sql (views)
- **SRC** – generate_data.py (data generator) and load_data.sql (the data it generates)
- **DUMP** – flighttrack_dump.sql (database after the data load)

## How to run (MySQL Workbench)
1. ex2.sql – creates the `flighttrack` schema
2. ex3.sql – three types of INSERT (run before the load)
3. SRC/load_data.sql – loads the generated data (16,170 tuples)
4. ex5.sql – seven queries
5. ex6.sql – three data modifications
6. ex7.sql – two views; run one statement at a time, since four modification attempts are meant to fail

7. ## Report guide (DESC PDF, 17 pages)

| Section | Pages | What's in it | Screenshots | SQL file |
|---|---|---|---|---|
| Overview | 1 | What the database is; simulated "present" = 15 Nov 2026, 12:00 | – | – |
| Item 2 – Schema | 1–3 | Keys and foreign key actions, 12 CHECK constraints, 4 indexes, 2 triggers | 2.1 (CREATE output), 2.2–2.7 (DESCRIBE each table) | ex2.sql |
| Item 3 – Three INSERT types | 4–5 | Positional INSERT, multi-row INSERT with column list, INSERT … SELECT | 3.1 (responses), 3.2 (SELECT * result) | ex3.sql |
| Item 4 – Generated data | 5–8 | Why a program, how it works, no duplicate keys, joinable foreign keys, table sizes, 5 sample records per relation, dump | 4.1 (tuple counts) | SRC/, DUMP/ |
| Item 5 – Queries | 8–12 | Q1 plain; Q2 join, Q3 GROUP BY/HAVING, Q4 EXISTS, Q5 >= ALL, Q6 LEFT OUTER JOIN, Q7 UNION | 5.1–5.7 | ex5.sql |
| Item 6 – Modifications | 13–14 | M1 INSERT … SELECT, M2 multi-row UPDATE, M3 subset DELETE | 6.1 (responses), 6.2 (check) | ex6.sql |
| Item 7 – Views | 14–17 | AirlinePerformance (not updatable), StaffMember (updatable, WITH CHECK OPTION), modification attempts, updatability explained | 7.1, 7.2 (queries), 7.3 (modification attempts) | ex7.sql |

To regenerate the data: `python generate_data.py` (standard library only, fixed seed).
