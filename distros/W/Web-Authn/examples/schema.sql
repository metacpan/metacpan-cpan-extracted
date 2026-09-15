-- Web::Authn sample schema
-- SQLite as written. PostgreSQL: BLOB -> BYTEA, INTEGER backed_up -> BOOLEAN.

CREATE TABLE users (
     id            INTEGER PRIMARY KEY
    ,email         TEXT    NOT NULL UNIQUE
    ,display_name  TEXT    NOT NULL
    ,user_handle   BLOB    NOT NULL UNIQUE
);

CREATE TABLE credentials (
     id              INTEGER PRIMARY KEY
    ,user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
    ,credential_id   BLOB    NOT NULL UNIQUE
    ,public_key      BLOB    NOT NULL
    ,sign_count      INTEGER NOT NULL DEFAULT 0
    ,aaguid          TEXT
    ,fmt             TEXT
    ,transports      TEXT
    ,device_type     TEXT
    ,backed_up       INTEGER NOT NULL DEFAULT 0
    ,created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX credentials_user ON credentials(user_id);

CREATE TABLE webauthn_challenges (
     id          INTEGER PRIMARY KEY
    ,session_id  TEXT    NOT NULL
    ,purpose     TEXT    NOT NULL
    ,challenge   BLOB    NOT NULL
    ,user_id     INTEGER
    ,expires_at  INTEGER NOT NULL
);

CREATE INDEX webauthn_challenges_session ON webauthn_challenges(session_id);
