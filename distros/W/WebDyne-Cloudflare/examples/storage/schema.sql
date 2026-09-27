CREATE TABLE IF NOT EXISTS webdyne_d1_example (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    note TEXT,
    payload BLOB
) STRICT;

DELETE FROM webdyne_d1_example;

INSERT INTO webdyne_d1_example (name, note, payload)
VALUES ('WebDyne example', 'A prepared D1 query from a PSP page', X'0001FF');
