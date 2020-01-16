-- Example SQLite:

DROP TABLE IF EXISTS account;
CREATE TABLE account (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    active INTEGER NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO account (name, password, active) VALUES ('Gene', 'abc123', 1);
