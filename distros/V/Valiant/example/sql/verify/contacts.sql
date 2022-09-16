-- Verify example:contacts on sqlite

BEGIN;

-- XXX Add verifications here.
select 1 from contact;
select 1 from contact_email;
select 1 from contact_phone;

ROLLBACK;
