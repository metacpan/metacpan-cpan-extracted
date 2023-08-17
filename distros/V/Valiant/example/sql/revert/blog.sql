-- Revert example:blog from sqlite

BEGIN;

DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS posts;
COMMIT;
