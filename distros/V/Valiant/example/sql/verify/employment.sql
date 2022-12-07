-- Verify example:employment on sqlite

BEGIN;

-- XXX Add verifications here.

select 1 from employment;
select employment_id from profile limit 1;

ROLLBACK;
