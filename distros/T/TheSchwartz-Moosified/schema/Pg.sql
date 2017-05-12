SET client_encoding = 'UTF8';
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

-- Created by: Michael Zedeler <michael@zedeler.dk>

CREATE TABLE PREFIX_funcmap (
        funcid SERIAL PRIMARY KEY NOT NULL,
        funcname       VARCHAR(255) NOT NULL,
        UNIQUE(funcname)
);

CREATE TABLE PREFIX_job (
        jobid           SERIAL PRIMARY KEY NOT NULL,
        funcid          INT NOT NULL,
        arg             BYTEA,
        uniqkey         VARCHAR(255) NULL,
        insert_time     INTEGER,
        run_after       INTEGER NOT NULL,
        grabbed_until   INTEGER NOT NULL,
        priority        SMALLINT,
        coalesce        VARCHAR(255),
        UNIQUE(funcid, uniqkey)
);

CREATE INDEX PREFIX_job_funcid_runafter ON PREFIX_job (funcid, run_after);
CREATE INDEX PREFIX_job_funcid_coalesce ON PREFIX_job (funcid, coalesce text_pattern_ops);
CREATE INDEX PREFIX_job_coalesce ON PREFIX_job (coalesce text_pattern_ops);
CREATE INDEX PREFIX_job_piro_non_null
	    ON PREFIX_job ((COALESCE((priority)::integer, 0)));

CREATE TABLE PREFIX_note (
        jobid           BIGINT NOT NULL,
        notekey         VARCHAR(255),
        PRIMARY KEY (jobid, notekey),
        value           BYTEA
);

CREATE TABLE PREFIX_error (
        error_time      INTEGER NOT NULL,
        jobid           BIGINT NOT NULL,
        message         TEXT NOT NULL,
        funcid          INT NOT NULL DEFAULT 0
);

CREATE INDEX PREFIX_error_funcid_errortime ON PREFIX_error (funcid, error_time);
CREATE INDEX PREFIX_error_time ON PREFIX_error (error_time);
CREATE INDEX PREFIX_error_jobid ON PREFIX_error (jobid);

CREATE TABLE PREFIX_exitstatus (
        jobid           BIGINT PRIMARY KEY NOT NULL,
        funcid          INT NOT NULL DEFAULT 0,
        status          SMALLINT,
        completion_time INTEGER,
        delete_after    INTEGER
);

CREATE INDEX PREFIX_exitstatus_funcid ON PREFIX_exitstatus (funcid);
CREATE INDEX PREFIX_exitstatus_deleteafter ON PREFIX_exitstatus (delete_after);
