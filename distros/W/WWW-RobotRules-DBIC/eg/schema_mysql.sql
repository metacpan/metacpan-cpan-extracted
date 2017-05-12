
CREATE TABLE user_agent (
       id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
       name VARCHAR(255),
       created_on DATETIME,
       UNIQUE KEY(name)
);

CREATE TABLE netloc (
       id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
       user_agent_id INT UNSIGNED NOT NULL,
       netloc VARCHAR(64) NOT NULL,
       count INT UNSIGNED DEFAULT 0 NOT NULL,
       visited_on DATETIME,
       fresh_until DATETIME,
       created_on DATETIME,
       UNIQUE KEY netloc(user_agent_id, netloc)
);

CREATE TABLE rule (
       id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
       netloc_id INT UNSIGNED NOT NULL,
       rule VARCHAR(255) NOT NULL,
       created_on DATETIME,
       UNIQUE KEY(netloc_id, rule)
);