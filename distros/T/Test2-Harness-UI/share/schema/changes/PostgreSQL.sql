-- Migration: Schema audit improvements for PostgreSQL
-- Apply to databases created with the previous version of share/schema/PostgreSQL.sql

-- 1. Widen pw_hash and pw_salt columns
ALTER TABLE users ALTER COLUMN pw_hash TYPE VARCHAR(128);
ALTER TABLE users ALTER COLUMN pw_salt TYPE VARCHAR(64);

-- 2. Add created timestamp to email_verification_codes
ALTER TABLE email_verification_codes ADD COLUMN created TIMESTAMP NOT NULL DEFAULT now();

-- 3. Add created timestamp to sessions
ALTER TABLE sessions ADD COLUMN created TIMESTAMP NOT NULL DEFAULT now();

-- 4. Add CHECK constraint to log_files
ALTER TABLE log_files ADD CONSTRAINT log_files_has_data CHECK (local_file IS NOT NULL OR data IS NOT NULL);

-- 5. Add ON DELETE CASCADE to sweeps.run_id
ALTER TABLE sweeps DROP CONSTRAINT sweeps_run_id_fkey;
ALTER TABLE sweeps ADD CONSTRAINT sweeps_run_id_fkey FOREIGN KEY (run_id) REFERENCES runs(run_id) ON DELETE CASCADE;

-- 6. Fix sweeps unique constraint column order (name, run_id) -> (run_id, name)
ALTER TABLE sweeps DROP CONSTRAINT sweeps_name_run_id_key;
ALTER TABLE sweeps ADD CONSTRAINT sweeps_run_id_name_key UNIQUE (run_id, name);

-- 7. Add ON DELETE CASCADE to run_fields.run_id
ALTER TABLE run_fields DROP CONSTRAINT run_fields_run_id_fkey;
ALTER TABLE run_fields ADD CONSTRAINT run_fields_run_id_fkey FOREIGN KEY (run_id) REFERENCES runs(run_id) ON DELETE CASCADE;

-- 8. Add ON DELETE CASCADE to job_fields.job_key
ALTER TABLE job_fields DROP CONSTRAINT job_fields_job_key_fkey;
ALTER TABLE job_fields ADD CONSTRAINT job_fields_job_key_fkey FOREIGN KEY (job_key) REFERENCES jobs(job_key) ON DELETE CASCADE;

-- 9. Add ON DELETE CASCADE to events.job_key
ALTER TABLE events DROP CONSTRAINT events_job_key_fkey;
ALTER TABLE events ADD CONSTRAINT events_job_key_fkey FOREIGN KEY (job_key) REFERENCES jobs(job_key) ON DELETE CASCADE;

-- 10. Add ON DELETE CASCADE to binaries.event_id
ALTER TABLE binaries DROP CONSTRAINT binaries_event_id_fkey;
ALTER TABLE binaries ADD CONSTRAINT binaries_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE;

-- 11. Add ON DELETE CASCADE to resources.resource_batch_id
ALTER TABLE resources DROP CONSTRAINT resources_resource_batch_id_fkey;
ALTER TABLE resources ADD CONSTRAINT resources_resource_batch_id_fkey FOREIGN KEY (resource_batch_id) REFERENCES resource_batch(resource_batch_id) ON DELETE CASCADE;

-- 12. Add ON DELETE SET NULL to reporting.event_id
ALTER TABLE reporting DROP CONSTRAINT reporting_event_id_fkey;
ALTER TABLE reporting ADD CONSTRAINT reporting_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE SET NULL;

-- 13. Drop redundant reporting_a index (prefix of reporting_b)
DROP INDEX IF EXISTS reporting_a;

-- 14. Add missing indexes for sweeper bulk operations
CREATE INDEX IF NOT EXISTS reporting_run ON reporting(run_id);
CREATE INDEX IF NOT EXISTS reporting_job ON reporting(job_key);
CREATE INDEX IF NOT EXISTS binaries_event ON binaries(event_id);
CREATE INDEX IF NOT EXISTS resource_batch_run ON resource_batch(run_id);
