
CREATE TABLE user_agent (
       id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
       name VARCHAR(255),
       created_on DATETIME,
       UNIQUE(name)
);

CREATE TABLE netloc (
       id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
       user_agent_id INTEGER NOT NULL,
       netloc VARCHAR(64) NOT NULL,
       count INTEGER DEFAULT 0 NOT NULL,
       visited_on DATETIME,
       fresh_until DATETIME,
       created_on DATETIME,
       UNIQUE (user_agent_id, netloc)
);

CREATE TABLE rule (
       id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
       netloc_id INTEGER NOT NULL,
       rule VARCHAR(255) NOT NULL,
       created_on DATETIME,
       UNIQUE (netloc_id, rule)
);