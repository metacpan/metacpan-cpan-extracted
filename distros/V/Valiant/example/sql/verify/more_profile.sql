-- Verify example:more_profile on sqlite

BEGIN;

-- XXX Add verifications here.
select status, registered from profile limit 1;

ROLLBACK;
