CREATE TABLE if not exists sessions (
    id           CHAR(72) PRIMARY KEY,
    created INTEGER,
    updated INTEGER,
    session_data TEXT
);
