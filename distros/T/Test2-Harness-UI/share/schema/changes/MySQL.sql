-- Migration: Schema audit improvements for MySQL
-- Apply to databases created with the previous version of share/schema/MySQL.sql

-- 1. Widen pw_hash and pw_salt columns
ALTER TABLE users MODIFY COLUMN pw_hash VARCHAR(128) DEFAULT NULL;
ALTER TABLE users MODIFY COLUMN pw_salt VARCHAR(64) DEFAULT NULL;

-- 2. Add created timestamp to email_verification_codes
ALTER TABLE email_verification_codes ADD COLUMN created TIMESTAMP NOT NULL DEFAULT now();

-- 3. Add created timestamp to sessions
ALTER TABLE sessions ADD COLUMN created TIMESTAMP NOT NULL DEFAULT now();

-- 4. Add ON DELETE CASCADE to sweeps.run_id
ALTER TABLE sweeps DROP FOREIGN KEY sweeps_ibfk_1;
ALTER TABLE sweeps ADD CONSTRAINT sweeps_ibfk_1 FOREIGN KEY (run_id) REFERENCES runs(run_id) ON DELETE CASCADE;

-- 5. Add ON DELETE CASCADE to run_fields.run_id
ALTER TABLE run_fields DROP FOREIGN KEY run_fields_ibfk_1;
ALTER TABLE run_fields ADD CONSTRAINT run_fields_ibfk_1 FOREIGN KEY (run_id) REFERENCES runs(run_id) ON DELETE CASCADE;

-- 6. Add ON DELETE CASCADE to job_fields.job_key
ALTER TABLE job_fields DROP FOREIGN KEY job_fields_ibfk_1;
ALTER TABLE job_fields ADD CONSTRAINT job_fields_ibfk_1 FOREIGN KEY (job_key) REFERENCES jobs(job_key) ON DELETE CASCADE;

-- 7. Add ON DELETE CASCADE to events.job_key
ALTER TABLE events DROP FOREIGN KEY events_ibfk_1;
ALTER TABLE events ADD CONSTRAINT events_ibfk_1 FOREIGN KEY (job_key) REFERENCES jobs(job_key) ON DELETE CASCADE;

-- 8. Add ON DELETE CASCADE to binaries.event_id
ALTER TABLE binaries DROP FOREIGN KEY binaries_ibfk_1;
ALTER TABLE binaries ADD CONSTRAINT binaries_ibfk_1 FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE;

-- 9. Add ON DELETE CASCADE to resources.resource_batch_id
ALTER TABLE resources DROP FOREIGN KEY resources_ibfk_1;
ALTER TABLE resources ADD CONSTRAINT resources_ibfk_1 FOREIGN KEY (resource_batch_id) REFERENCES resource_batch(resource_batch_id) ON DELETE CASCADE;

-- 10. Add ON DELETE SET NULL to reporting.event_id
ALTER TABLE reporting DROP FOREIGN KEY reporting_ibfk_6;
ALTER TABLE reporting ADD CONSTRAINT reporting_ibfk_6 FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE SET NULL;

-- 11. Drop redundant reporting_a index (prefix of reporting_b)
DROP INDEX reporting_a ON reporting;

-- 12. Add missing indexes for sweeper bulk operations
CREATE INDEX reporting_run ON reporting(run_id);
CREATE INDEX reporting_job ON reporting(job_key);
CREATE INDEX binaries_event ON binaries(event_id);
CREATE INDEX resource_batch_run ON resource_batch(run_id);
