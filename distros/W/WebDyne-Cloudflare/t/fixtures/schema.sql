CREATE TABLE IF NOT EXISTS webdyne_d1_batch_test (
    token TEXT NOT NULL,
    slot INTEGER NOT NULL,
    name TEXT,
    note TEXT,
    payload BLOB,
    PRIMARY KEY (token, slot)
);

CREATE TABLE IF NOT EXISTS webdyne_d1_example (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    note TEXT,
    payload BLOB
) STRICT;

DELETE FROM webdyne_d1_example;

INSERT INTO webdyne_d1_example (name, note, payload)
VALUES ('Milestone 2', 'WebDyne::Cloudflare::D1 fixture', X'0001FF');
