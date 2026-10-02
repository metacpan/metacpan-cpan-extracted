-- Migration: analytics indexes for PostgreSQL
-- Apply to databases created before these indexes were added to share/schema/PostgreSQL.sql
--
-- Requested in https://github.com/Test-More/Test2-Harness/issues/457, which
-- was filed on the wrong repo (Test2-Harness rather than Test2-Harness-UI).

-- 1. Reporting queries that look back over many runs in a window
CREATE INDEX IF NOT EXISTS reporting_run_analytics ON reporting(run_id, test_file_id, subtest, pass, fail, duration);

-- 2. Run field lookups by name
CREATE INDEX IF NOT EXISTS run_fields_name ON run_fields(name);
