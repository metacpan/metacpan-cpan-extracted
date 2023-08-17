-- Verify example:blog on sqlite

BEGIN;

select 1 from posts;
select 1 from comments;

ROLLBACK;
